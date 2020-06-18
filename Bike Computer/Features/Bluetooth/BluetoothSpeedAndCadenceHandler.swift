import CoreBluetooth
import Combine

class BluetoothSpeedAndCadenceHandler: NSObject {
    
    var cadence: Published<Double>.Publisher { $_cadence }
    @Published private var _cadence: Double = 0
    
    var speed: Published<Double>.Publisher { $_speed }
    @Published private var _speed: Double = 0
    
    var distanceInMeters: Published<Double>.Publisher { $_distanceInMeters }
    @Published private var _distanceInMeters: Double = 0
    
    // MARK: - Class Constants
    static let speedAndCadenceServiceCBUUID = CBUUID(string: "1816")
    
    // MARK: - Private Properties
    private let cyclingSpeedAndCadenceMeasurementCharacteristicsCBUUID = CBUUID(string: "2a5b")
    private let cyclingSpeedAndCadenceFeatureCharacteristicsCBUUID = CBUUID(string: "2a5c")
    private let sensorLocationCharacteristicsCBUUID = CBUUID(string: "2a5d")
    private let speedAndCadenceControlPointCBUUID = CBUUID(string: "2a55")
    
    private var lastMeasurement: BluetoothSpeedAndCadenceDataPoint?
    
    private func handleMeasurement(_ data: Data) {
        let measurement = BluetoothSpeedAndCadenceDataPoint(NSData(data: data))
        print(measurement)
        
        let values = measurement.valuesForPreviousMeasurement(previousSample: lastMeasurement)
        lastMeasurement = measurement
        
        if let speed = values?.speedInMetersPerSecond {
            _speed = speed
        }
        
        if let cadence = values?.cadenceinRPM {
            _cadence = cadence
        }
        
        if let distanceInMeters = values?.distanceinMeters {
            _distanceInMeters = distanceInMeters
        }
    }
}

extension BluetoothSpeedAndCadenceHandler: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Received an Error in didUpdateNotificationState \(error)")
            
            return
        }
        
        print("notification status changed for [\(characteristic.uuid)]...")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            print(service)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            print(characteristic)
            
            if characteristic.properties.contains(.read) {
                print("\(characteristic.uuid): properties contains .read")
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.notify) {
                print("\(characteristic.uuid): properties contains .notify")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
        case cyclingSpeedAndCadenceMeasurementCharacteristicsCBUUID:
            guard let data = characteristic.value else { return }
            
            handleMeasurement(data)
        case cyclingSpeedAndCadenceFeatureCharacteristicsCBUUID:
            print("cyclingSpeedAndCadenceMeasurementCBUUID: \(characteristic)")
        case sensorLocationCharacteristicsCBUUID:
            print("sensorLocationCharacteristicsCBUUID: \(characteristic)")
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
}

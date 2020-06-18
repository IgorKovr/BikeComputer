import CoreBluetooth

class BluetoothSpeedAndCadenceHandler: NSObject {
    
    // MARK: - Class Constants
    static let speedAndCadenceServiceCBUUID = CBUUID(string: "1816")
    
    // MARK: - Private Properties
    private let cyclingSpeedAndCadenceMeasurementCharacteristicsCBUUID = CBUUID(string: "2a5b")
    private let cyclingSpeedAndCadenceFeatureCharacteristicsCBUUID = CBUUID(string: "2a5c")
    private let sensorLocationCharacteristicsCBUUID = CBUUID(string: "2a5d")
    private let speedAndCadenceControlPointCBUUID = CBUUID(string: "2a55")
}

extension BluetoothSpeedAndCadenceHandler: CBPeripheralDelegate {
    
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
            print("cyclingSpeedAndCadenceMeasurementCharacteristicsCBUUID: \(characteristic)")
        case cyclingSpeedAndCadenceFeatureCharacteristicsCBUUID:
            print("cyclingSpeedAndCadenceMeasurementCBUUID: \(characteristic)")
        case sensorLocationCharacteristicsCBUUID:
            print("sensorLocationCharacteristicsCBUUID: \(characteristic)")
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
}

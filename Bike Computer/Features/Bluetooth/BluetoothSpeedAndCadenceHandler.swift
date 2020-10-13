import CoreBluetooth
import Combine

class BluetoothSpeedAndCadenceHandler: NSObject, ServiceHandling {

    // MARK: - Public Properties

    let uuid = CBUUID(string: "1816")
    var isConnected: Bool = false
    var cadence: Published<Double>.Publisher { $_cadence }
    @Published private var _cadence: Double = 0
    var speedInMetersPerSecond: Published<Double>.Publisher { $_speedInMetersPerSecond }
    @Published private var _speedInMetersPerSecond: Double = 0
    var distanceInMeters: Published<Double>.Publisher { $_distanceInMeters }
    @Published private var _distanceInMeters: Double = 0

    // MARK: - Private Properties
    private let measurementCharacteristicsCBUUID = CBUUID(string: "2a5b")
    private let featureCharacteristicsCBUUID = CBUUID(string: "2a5c")
    private let sensorLocationCharacteristicsCBUUID = CBUUID(string: "2a5d")
    private let controlPointCBUUID = CBUUID(string: "2a55")

    /// Imperical value for wheel Circumference
    /// Diameter * Pi
    /// ~ 680 * 3.14 (680 is a comon actual diameter for 700c wheel)
    private let defaultWheelСircumferenceInMeters: Double = 2096/1000

    private var firstMeasurement: BluetoothSpeedAndCadenceDataPoint?
    private var lastMeasurement: BluetoothSpeedAndCadenceDataPoint?

    private func handleMeasurement(_ data: Data) {
        let measurement = BluetoothSpeedAndCadenceDataPoint(NSData(data: data),
                                                            wheelСircumference: defaultWheelСircumferenceInMeters)

        firstMeasurement = firstMeasurement ?? measurement

        let values = measurement.valuesForPreviousMeasurement(previousSample: lastMeasurement)
        lastMeasurement = measurement

        if let speed = values?.speedInMetersPerSecond {
            _speedInMetersPerSecond = speed
        }

        if let cadence = values?.cadenceinRPM {
            _cadence = cadence
        }

        _distanceInMeters = calculateDistance()
    }

    private func calculateDistance() -> Double {
        guard let firstMeasurementCumulativeWheelRevolutions = firstMeasurement?.cumulativeWheelRevolutions,
            let lastMeasurementCumulativeWheelRevolutions = lastMeasurement?.cumulativeWheelRevolutions else {
                return 0.0
        }

        return Double(lastMeasurementCumulativeWheelRevolutions - firstMeasurementCumulativeWheelRevolutions) * defaultWheelСircumferenceInMeters
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
        case measurementCharacteristicsCBUUID:
            guard let data = characteristic.value else { return }

            handleMeasurement(data)
        case featureCharacteristicsCBUUID:
            print("cyclingSpeedAndCadenceMeasurementCBUUID: \(characteristic)")
        case sensorLocationCharacteristicsCBUUID:
            print("sensorLocationCharacteristicsCBUUID: \(characteristic)")
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
}

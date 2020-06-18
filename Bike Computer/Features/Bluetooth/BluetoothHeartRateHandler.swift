//
//  BluetoothHeartRateHandler.swift
//  Bike Computer
//
//  Created by Igor Kovryzhkin on 17.06.20.
//  Copyright © 2020 IgorK. All rights reserved.
//

import CoreBluetooth

protocol BluetoothHeartRatePeripheralHandling: NSObject, CBPeripheralDelegate {
    
    var heartRate: Published<Int>.Publisher { get }
}

class BluetoothHeartRatePeripheralHandler: NSObject, BluetoothHeartRatePeripheralHandling {
    
    // MARK: - Public Properteis
    
    var heartRate: Published<Int>.Publisher { $_heartRate }
    
    @Published private var _heartRate: Int = 0
    @Published private var _hrSensorBodyLocation: String? = nil
    
    // MARK: Constants
    
    static let heartRateServiceCBUUID = CBUUID(string: "0x180D")
    
    // MARK: - Private Properties
    
    // MARK: Constants
    private let heartRateMeasurementCharacteristicCBUUID = CBUUID(string: "2A37")
    private let bodySensorLocationCharacteristicCBUUID = CBUUID(string: "2A38")
    
    // MARK: - Private functions
    
    private func onHeartRateReceived(_ heartRate: Int) {
        self._heartRate = heartRate
        print("BPM: \(heartRate)")
    }
    
    private func onBodyLocationReceived(_ location: String) {
        self._hrSensorBodyLocation = location
        print("Body Location:" + location)
    }
}

//// MARK: - CBPeripheralDelegate

extension BluetoothHeartRatePeripheralHandler: CBPeripheralDelegate {
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
    case bodySensorLocationCharacteristicCBUUID:
      onBodyLocationReceived(bodyLocation(from: characteristic))
    case heartRateMeasurementCharacteristicCBUUID:
      onHeartRateReceived(heartRate(from: characteristic))
    default:
      print("Unhandled Characteristic UUID: \(characteristic.uuid)")
    }
  }
    
    private func heartRate(from characteristic: CBCharacteristic) -> Int {
      guard let characteristicData = characteristic.value else { return -1 }
      let byteArray = [UInt8](characteristicData)

      // See: https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.heart_rate_measurement.xml
      // The heart rate mesurement is in the 2nd, or in the 2nd and 3rd bytes, i.e. one one or in two bytes
      // The first byte of the first bit specifies the length of the heart rate data, 0 == 1 byte, 1 == 2 bytes
      let firstBitValue = byteArray[0] & 0x01
      if firstBitValue == 0 {
        // Heart Rate Value Format is in the 2nd byte
        return Int(byteArray[1])
      } else {
        // Heart Rate Value Format is in the 2nd and 3rd bytes
        return (Int(byteArray[1]) << 8) + Int(byteArray[2])
      }
    }
    
    private func bodyLocation(from characteristic: CBCharacteristic) -> String {
      guard let characteristicData = characteristic.value,
        let byte = characteristicData.first else { return "Error" }

      switch byte {
      case 0: return "Other"
      case 1: return "Chest"
      case 2: return "Wrist"
      case 3: return "Finger"
      case 4: return "Hand"
      case 5: return "Ear Lobe"
      case 6: return "Foot"
      default:
        return "Reserved for future use"
      }
    }
}

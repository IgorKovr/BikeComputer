//
//  BluetoothService.swift
//  Bike Computer
//
//  Created by Igor Kovryzhkin on 16.06.20.
//  Copyright © 2020 IgorK. All rights reserved.
//

import CoreBluetooth

protocol BluetoothServiceProtocol {
    
    var heartRate: Published<Int>.Publisher { get }
    func startBluetoothScan()
}

class BluetoothService: NSObject, BluetoothServiceProtocol {
    
    // MARK: - Public Properties
    
    var heartRate: Published<Int>.Publisher { heartRatePeripheralHandler.heartRate }
    
    // MARK: - Private Properties
    
    private var centralManager: CBCentralManager!
    private var heartRatePeripheral: CBPeripheral!
    private let heartRatePeripheralHandler: BluetoothHeartRatePeripheralHandling
    
    // MARK: Constants
    
    private let supportedPeripheralServices = [BluetoothHeartRatePeripheralHandler.heartRateServiceCBUUID]
    
    // MARK: - Initializers
    
    init(heartRatePeripheralHandler: BluetoothHeartRatePeripheralHandling = BluetoothHeartRatePeripheralHandler()) {
        self.heartRatePeripheralHandler = heartRatePeripheralHandler
    }
    
    // MARK: - Public Functions

    func startBluetoothScan() {
      centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    private func logBluetoothManagerState(_ state: CBManagerState) {
        switch state {
        case .unknown:
          print("central.state is .unknown")
        case .resetting:
          print("central.state is .resetting")
        case .unsupported:
          print("central.state is .unsupported")
        case .unauthorized:
          print("central.state is .unauthorized")
        case .poweredOff:
          print("central.state is .poweredOff")
        case .poweredOn:
          print("central.state is .poweredOn")
        @unknown default:
            print("central.state is unknown")
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothService: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            centralManager.scanForPeripherals(withServices: supportedPeripheralServices)
        default: break
        }
        
        logBluetoothManagerState(central.state)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                      advertisementData: [String : Any], rssi RSSI: NSNumber) {
    print("Discovered peripheral: \(peripheral)")
        
    // FIXME: Distinguish peripherals
    heartRatePeripheral = peripheral
    heartRatePeripheral.delegate = heartRatePeripheralHandler
    // FIXME: Should we keep scanning?
    centralManager.stopScan()
        
    centralManager.connect(heartRatePeripheral)
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    print("Connected peripheral: \(peripheral)")
    heartRatePeripheral.discoverServices([BluetoothHeartRatePeripheralHandler.heartRateServiceCBUUID])
  }
}

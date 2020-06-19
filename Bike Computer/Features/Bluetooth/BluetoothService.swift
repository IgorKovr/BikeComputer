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
    var cadence: Published<Double>.Publisher { get }
    var speed: Published<Double>.Publisher { get }
    var distanceInMeters: Published<Double>.Publisher { get }
    
    func startBluetoothScan()
}

class BluetoothService: NSObject, BluetoothServiceProtocol {
    
    // MARK: - Public Properties
    
    var heartRate: Published<Int>.Publisher { heartRatePeripheralHandler.heartRate }
    var cadence: Published<Double>.Publisher { bikePowerHandler.cadence }
    var speed: Published<Double>.Publisher { bikePowerHandler.speed }
    var distanceInMeters: Published<Double>.Publisher { bikePowerHandler.distanceInMeters }
    
    // MARK: - Private Properties
    
    private var centralManager: CBCentralManager!
    private var heartRatePeripheral: CBPeripheral!
    private var speedAndCadencePeripheral: CBPeripheral!
    
    private let heartRatePeripheralHandler: BluetoothHeartRatePeripheralHandling
    private let bikePowerHandler: BluetoothSpeedAndCadenceHandler
    
    // MARK: Constants
    
    private let supportedPeripheralServices = [
        // TODO Activate back the heartRate
        //        BluetoothHeartRatePeripheralHandler.heartRateServiceCBUUID,
        BluetoothSpeedAndCadenceHandler.speedAndCadenceServiceCBUUID
    ]
    
    // MARK: - Initializers
    
    init(heartRatePeripheralHandler: BluetoothHeartRatePeripheralHandling = BluetoothHeartRatePeripheralHandler(),
         bikePowerHandler: BluetoothSpeedAndCadenceHandler = BluetoothSpeedAndCadenceHandler()) {
        self.heartRatePeripheralHandler = heartRatePeripheralHandler
        self.bikePowerHandler = bikePowerHandler
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
        
        // TODO: Distinguish peripherals
        
        //    heartRatePeripheral = peripheral
        //    heartRatePeripheral.delegate = heartRatePeripheralHandler
        
        speedAndCadencePeripheral = peripheral
        speedAndCadencePeripheral.delegate = bikePowerHandler
        
        // TODO: We should scan more until we all supported peripheral
        centralManager.stopScan()
        
        centralManager.connect(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected peripheral: \(peripheral)")
        
        // TODO: Distinguish the Services
        peripheral.discoverServices(supportedPeripheralServices)
    }
}

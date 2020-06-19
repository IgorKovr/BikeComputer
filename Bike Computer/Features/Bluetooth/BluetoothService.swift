//
//  BluetoothService.swift
//  Bike Computer
//
//  Created by Igor Kovryzhkin on 16.06.20.
//  Copyright © 2020 IgorK. All rights reserved.
//

import CoreBluetooth

protocol ServiceHandling: CBPeripheralDelegate {
    
    var isConnected: Bool { get set }
    var uuid: CBUUID { get }
}

protocol BluetoothServiceProtocol {
    
    var heartRate: Published<Int>.Publisher { get }
    var cadence: Published<Double>.Publisher { get }
    var speedInMetersPerSecond: Published<Double>.Publisher { get }
    var distanceInMeters: Published<Double>.Publisher { get }
    
    func startBluetoothScan()
}

class BluetoothService: NSObject, BluetoothServiceProtocol {
    
    // MARK: - Public Properties
    
    var heartRate: Published<Int>.Publisher { heartRatePeripheralHandler.heartRate }
    var cadence: Published<Double>.Publisher { bikePowerHandler.cadence }
    var speedInMetersPerSecond: Published<Double>.Publisher { bikePowerHandler.speedInMetersPerSecond }
    var distanceInMeters: Published<Double>.Publisher { bikePowerHandler.distanceInMeters }
    
    // MARK: - Private Properties
    
    private let heartRatePeripheralHandler: BluetoothHeartRatePeripheralHandling
    private let bikePowerHandler: BluetoothSpeedAndCadenceHandler
    
    private var centralManager: CBCentralManager!
    private var supportedPeripherals = [CBPeripheral]()
    private var services: [ServiceHandling]
    private var currentServiceForScan: ServiceHandling? = nil
    
    
    // MARK: - Initializers
    
    init(heartRatePeripheralHandler: BluetoothHeartRatePeripheralHandling = BluetoothHeartRatePeripheralHandler(),
         bikePowerHandler: BluetoothSpeedAndCadenceHandler = BluetoothSpeedAndCadenceHandler()) {
        self.heartRatePeripheralHandler = heartRatePeripheralHandler
        self.bikePowerHandler = bikePowerHandler
        
        services = [heartRatePeripheralHandler,
                    bikePowerHandler]
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
    
    func scanForNextService() {
        if let unconnectedServices = services.first(where: { $0.isConnected == false}) {
            currentServiceForScan = unconnectedServices
            centralManager.scanForPeripherals(withServices: [unconnectedServices.uuid])
        } else {
            centralManager.stopScan()
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothService: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            scanForNextService()
        default: break
        }
        
        logBluetoothManagerState(central.state)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered peripheral: \(peripheral)")

        supportedPeripherals.append(peripheral)
        peripheral.delegate = currentServiceForScan
        
        centralManager.stopScan()
        centralManager.connect(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected peripheral: \(peripheral)")
        
        guard let currentServiceForScan = currentServiceForScan else { return }
        
        peripheral.discoverServices([currentServiceForScan.uuid])
        currentServiceForScan.isConnected = true
        scanForNextService()
    }
}

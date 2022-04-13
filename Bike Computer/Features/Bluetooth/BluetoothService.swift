//
//  BluetoothService.swift
//  Bike Computer
//
//  Created by Igor Kovryzhkin on 16.06.20.
//  Copyright © 2020 IgorK. All rights reserved.
//

import CoreBluetooth

/// Describes a Handler for a Bluetooth device
protocol BletoothDeviceHandling: CBPeripheralDelegate {

    var isConnected: Bool { get set }
    var uuid: CBUUID { get }
}

/// The service to handle Bluetooth connections
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

    // supportedPeripherals is used to keep strong reference to the connected Peripherals
    private var supportedPeripherals = [CBPeripheral]()
    private var services: [BletoothDeviceHandling]
    private var currentServiceForScan: BletoothDeviceHandling?

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

    // MARK: - Private Functions

    private func logBluetoothManagerState(_ state: CBManagerState) {
        switch state {
        case .unknown:
            print("Core Bluetooth is initializing or resets")
        case .resetting:
            print("Bluetooth is trying to reconnect")
        case .unsupported:
            print("Device doesn’t support the Bluetooth low energy central or client role")
        case .unauthorized:
            print("Application isn’t authorized to use the Bluetooth low energy role")
        case .poweredOff:
            print("Bluetooth is currently powered off")
        case .poweredOn:
            print("Bluetooth is currently powered on and available to use")
        @unknown default:
            print("Bluetooth state is unknown")
        }
    }

    private func scanForNextService() {
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
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        print("Discovered peripheral: \n \(peripheral)")

        supportedPeripherals.append(peripheral)
        peripheral.delegate = currentServiceForScan

        centralManager.stopScan()
        centralManager.connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected peripheral: \n \(peripheral)")

        guard let currentServiceForScan = currentServiceForScan else { return }

        peripheral.discoverServices([currentServiceForScan.uuid])
        currentServiceForScan.isConnected = true
        scanForNextService()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let disconnectedService = services.first(where: {
            peripheral.delegate?.isEqual($0) ?? false
        })

        disconnectedService?.isConnected = false
        scanForNextService()
    }
}

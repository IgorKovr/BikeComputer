//
//  BluetoothSpeedAndSensorDataPoint.swift
//  Bike Computer
//
//  Created by Igor Kovryzhkin on 18.06.20.
//  Copyright © 2020 IgorK. All rights reserved.
//

import CoreBluetooth

// CSC Measurement
// https://developer.bluetooth.org/gatt/characteristics/Pages/CharacteristicViewer.aspx?u=org.bluetooth.characteristic.csc_measurement.xml
//
//  Flags : 1 byte.  Bit 0: Wheel. Bit 1: Crank
//  Cumulative Wheel revolutions: 4 bytes uint32
//  Last wheel event time: 2 bytes. uint16 (1/1024s)
//  Cumulative Crank revolutions: 2 bytes uint16
//  Last crank event time: 2 bytes. uint16 (1/1024s)

struct BluetoothSpeedAndCadenceDataPoint {

    // MARK: - Constants
    private let wheelFlagMask: UInt8 = 0b01
    private let crankFlagMask: UInt8 = 0b10
    private let timeScale = 1024.0

    // MARK: - Public properties
    let cumulativeWheelRevolutions: UInt32

    // MARK: - Private properties

    private let isSpeedSensorAvailable: Bool
    private let isCadenceSensorAvailable: Bool
    private let lastWheelEventTime: TimeInterval
    private let cumulativeCrankRevolutions: UInt16
    private let lastCrankEventTime: TimeInterval
    private let wheelСircumference: Double

    init(_ data: NSData, wheelСircumference: Double) {
        self.wheelСircumference = wheelСircumference

        // Flags
        var flags: UInt8 = 0
        data.getBytes(&flags, range: NSRange(location: 0, length: 1))

        isSpeedSensorAvailable = (flags & wheelFlagMask) > 0
        isCadenceSensorAvailable = (flags & crankFlagMask) > 0

        var wheel: UInt32 = 0
        var wheelTime: UInt16 = 0
        var crank: UInt16 = 0
        var crankTime: UInt16 = 0
        var currentOffset = 1
        var length = 0

        if  isSpeedSensorAvailable {
            length = MemoryLayout<UInt32>.size
            data.getBytes(&wheel, range: NSRange(location: currentOffset, length: length))
            currentOffset += length

            length = MemoryLayout<UInt16>.size
            data.getBytes(&wheelTime, range: NSRange(location: currentOffset, length: length))
            currentOffset += length
        }

        if  isCadenceSensorAvailable {
            length = MemoryLayout<UInt16>.size
            data.getBytes(&crank, range: NSRange(location: currentOffset, length: length))
            currentOffset += length

            length = MemoryLayout<UInt16>.size
            data.getBytes(&crankTime, range: NSRange(location: currentOffset, length: length))
            currentOffset += length
        }

        cumulativeWheelRevolutions = CFSwapInt32LittleToHost(wheel)
        lastWheelEventTime = TimeInterval(Double(CFSwapInt16LittleToHost(wheelTime)) / timeScale)
        cumulativeCrankRevolutions = CFSwapInt16LittleToHost(crank)
        lastCrankEventTime = TimeInterval(Double(CFSwapInt16LittleToHost(crankTime)) / timeScale)
    }

    func valuesForPreviousMeasurement(previousSample: BluetoothSpeedAndCadenceDataPoint?) -> (cadenceinRPM: Double?, distanceinMeters: Double?, speedInMetersPerSecond: Double?)? {
        guard let previousSample = previousSample else { return nil }

        var distance: Double?, cadence: Double?, speedInMs: Double?
        if  isSpeedSensorAvailable && previousSample.isSpeedSensorAvailable {
            let wheelTimeDiff = timeIntervalForCurrentSample(lastWheelEventTime, previous: previousSample.lastWheelEventTime)

            let valueDiff = valueDiffForCurrentSample(cumulativeWheelRevolutions, previous: previousSample.cumulativeWheelRevolutions, max: UInt32.max)

            if valueDiff == 0 || wheelTimeDiff == 0 {
                return nil
            }

            distance = Double(valueDiff) * wheelСircumference // distance in meters
            if  distance != nil  &&  wheelTimeDiff > 0 {
                speedInMs = distance! / wheelTimeDiff // m/s
            }
        }

        if  isCadenceSensorAvailable && previousSample.isCadenceSensorAvailable {
            let crankDiffTime = timeIntervalForCurrentSample(lastCrankEventTime, previous: previousSample.lastCrankEventTime)
            let valueDiff = Double(valueDiffForCurrentSample(cumulativeCrankRevolutions, previous: previousSample.cumulativeCrankRevolutions, max: UInt16.max))

            cadence = (crankDiffTime == 0) ? nil : Double(60.0 * valueDiff / crankDiffTime) // RPM
        }
        print("Cadence: \(String(describing: cadence)) RPM. Distance: \(String(describing: distance)) meters. Speed: \(String(describing: speedInMs)) M/s")
        return (cadenceinRPM:cadence, distanceinMeters: distance, speedInMetersPerSecond: speedInMs)
    }

    // MARK: - Private functions

    private func timeIntervalForCurrentSample(_ current: TimeInterval, previous: TimeInterval) -> TimeInterval {
        var timeDiff: TimeInterval = 0
        if current >= previous {
            timeDiff = current - previous
        } else {
            // passed the maximum value
            timeDiff = (TimeInterval((Double( UINT16_MAX) / timeScale)) - previous) + current
        }
        return timeDiff
    }

}

extension BluetoothSpeedAndCadenceDataPoint {
    private func valueDiffForCurrentSample(_ current: Double, previous: Double, max: Double) -> Double {
        var diff: Double = 0
        if   current >= previous {
            diff = current - previous
        } else {
            diff = (max - previous) + current
        }
        return diff
    }

    private func valueDiffForCurrentSample(_ current: UInt32, previous: UInt32, max: UInt32) -> UInt32 {
        var diff: UInt32 = 0
        if   current >= previous {
            diff = current - previous
        } else {
            diff = (max - previous) + current
        }
        return diff
    }

    private func valueDiffForCurrentSample(_ current: UInt16, previous: UInt16, max: UInt16) -> UInt16 {
        var diff: UInt16 = 0
        if current >= previous {
            diff = current - previous
        } else {
            diff = (max - previous) + current
        }
        return diff
    }
}

extension BluetoothSpeedAndCadenceDataPoint: CustomDebugStringConvertible {
    var debugDescription: String {
        """
        Wheel Revs: \(cumulativeWheelRevolutions).
        Last wheel event time: \(lastWheelEventTime).
        Crank Revs: \(cumulativeCrankRevolutions).
        Last Crank event time: \(lastCrankEventTime)
        """
    }
}

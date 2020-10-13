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

struct BluetoothSpeedAndCadenceDataPoint: CustomDebugStringConvertible {

    private let wheelFlagMask: UInt8 = 0b01
    private let crankFlagMask: UInt8 = 0b10
    private let timeScale = 1024.0

    let hasWheel: Bool
    let hasCrank: Bool
    let cumulativeWheelRevolutions: UInt32
    let lastWheelEventTime: TimeInterval
    let cumulativeCrankRevolutions: UInt16
    let lastCrankEventTime: TimeInterval
    let wheelСircumference: Double

    init(_ data: NSData, wheelСircumference: Double) {

        self.wheelСircumference = wheelСircumference
        // Flags
        var flags: UInt8=0
        data.getBytes(&flags, range: NSRange(location: 0, length: 1))

        hasWheel = ((flags & wheelFlagMask) > 0)
        hasCrank = ((flags & crankFlagMask) > 0)

        var wheel: UInt32=0
        var wheelTime: UInt16=0
        var crank: UInt16=0
        var crankTime: UInt16=0

        var currentOffset = 1
        var length = 0

        if  hasWheel {

            length = MemoryLayout<UInt32>.size
            data.getBytes(&wheel, range: NSRange(location: currentOffset, length: length))
            currentOffset += length

            length = MemoryLayout<UInt16>.size
            data.getBytes(&wheelTime, range: NSRange(location: currentOffset, length: length))
            currentOffset += length
        }

        if  hasCrank {

            length = MemoryLayout<UInt16>.size
            data.getBytes(&crank, range: NSRange(location: currentOffset, length: length))
            currentOffset += length

            length = MemoryLayout<UInt16>.size
            data.getBytes(&crankTime, range: NSRange(location: currentOffset, length: length))
            currentOffset += length
        }

        cumulativeWheelRevolutions     = CFSwapInt32LittleToHost(wheel)
        lastWheelEventTime  = TimeInterval( Double(CFSwapInt16LittleToHost(wheelTime))/timeScale)
        cumulativeCrankRevolutions     = CFSwapInt16LittleToHost(crank)
        lastCrankEventTime  = TimeInterval( Double(CFSwapInt16LittleToHost(crankTime))/timeScale)
    }

    func timeIntervalForCurrentSample(_ current: TimeInterval, previous: TimeInterval ) -> TimeInterval {
        var timeDiff: TimeInterval = 0
        if  current >= previous {
            timeDiff = current - previous
        } else {
            // passed the maximum value
            timeDiff =  (TimeInterval((Double( UINT16_MAX) / timeScale)) - previous) + current
        }
        return timeDiff
    }

    func valuesForPreviousMeasurement( previousSample: BluetoothSpeedAndCadenceDataPoint? ) -> ( cadenceinRPM: Double?, distanceinMeters: Double?, speedInMetersPerSecond: Double?)? {

        var distance: Double?, cadence: Double?, speed: Double?
        guard let previousSample = previousSample else {
            return nil
        }
        if  hasWheel && previousSample.hasWheel {
            let wheelTimeDiff = timeIntervalForCurrentSample(lastWheelEventTime, previous: previousSample.lastWheelEventTime)

            let valueDiff = valueDiffForCurrentSample(cumulativeWheelRevolutions, previous: previousSample.cumulativeWheelRevolutions, max: UInt32.max)

            distance = Double(valueDiff) * wheelСircumference // distance in meters
            if  distance != nil  &&  wheelTimeDiff > 0 {
                speed = (wheelTimeDiff == 0 ) ? 0 : distance! / wheelTimeDiff // m/s
            }
        }

        if  hasCrank && previousSample.hasCrank {
            let crankDiffTime = timeIntervalForCurrentSample(lastCrankEventTime, previous: previousSample.lastCrankEventTime)
            let valueDiff = Double(valueDiffForCurrentSample(cumulativeCrankRevolutions, previous: previousSample.cumulativeCrankRevolutions, max: UInt16.max))

            cadence = (crankDiffTime == 0) ? 0 : Double(60.0 * valueDiff / crankDiffTime) // RPM
        }
        print("Cadence: \(String(describing: cadence)) RPM. Distance: \(String(describing: distance)) meters. Speed: \(String(describing: speed)) Km/h")
        return (cadenceinRPM:cadence, distanceinMeters:distance, speedInMetersPerSecond:speed)
    }

    var debugDescription: String {
        """
        Wheel Revs: \(cumulativeWheelRevolutions).
        Last wheel event time: \(lastWheelEventTime).
        Crank Revs: \(cumulativeCrankRevolutions).
        Last Crank event time: \(lastCrankEventTime)
        """
    }
}

extension BluetoothSpeedAndCadenceDataPoint {
    func valueDiffForCurrentSample(_ current: Double, previous: Double, max: Double) -> Double {
        var diff: Double = 0
        if   current >= previous {
            diff = current - previous
        } else {
            diff = ( max - previous ) + current
        }
        return diff
    }

    func valueDiffForCurrentSample(_ current: UInt32, previous: UInt32, max: UInt32) -> UInt32 {
        var diff: UInt32 = 0
        if   current >= previous {
            diff = current - previous
        } else {
            diff = ( max - previous ) + current
        }
        return diff
    }

    func valueDiffForCurrentSample(_ current: UInt16, previous: UInt16, max: UInt16) -> UInt16 {
        var diff: UInt16 = 0
        if   current >= previous {
            diff = current - previous
        } else {
            diff = ( max - previous ) + current
        }
        return diff
    }
}

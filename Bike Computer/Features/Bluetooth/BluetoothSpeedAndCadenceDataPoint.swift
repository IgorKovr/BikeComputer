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
    
    private let wheelFlagMask:UInt8    = 0b01
    private let crankFlagMask:UInt8    = 0b10
    static let defaultWheelSize:UInt32   = 700*30 // 2170  // In millimiters. 700x30 (by default my bike's wheels) :)
    private let timeScale              = 1024.0
    
    let hasWheel:Bool
    let hasCrank:Bool
    let cumulativeWheel:UInt32
    let lastWheelEventTime:TimeInterval
    let cumulativeCrank:UInt16
    let lastCrankEventTime:TimeInterval
    let wheelSize:UInt32
    
    
    init(_ data: NSData, wheelSize: UInt32 = Self.defaultWheelSize) {
        
        self.wheelSize = wheelSize
        // Flags
        var flags:UInt8=0
        data.getBytes(&flags, range: NSRange(location: 0, length: 1))
        
        hasWheel = ((flags & wheelFlagMask) > 0)
        hasCrank = ((flags & crankFlagMask) > 0)
        
        var wheel:UInt32=0
        var wheelTime:UInt16=0
        var crank:UInt16=0
        var crankTime:UInt16=0
        
        var currentOffset = 1
        var length = 0
        
        if ( hasWheel ) {
            
            length = MemoryLayout<UInt32>.size
            data.getBytes(&wheel, range: NSRange(location: currentOffset, length: length))
            currentOffset += length
            
            length = MemoryLayout<UInt16>.size
            data.getBytes(&wheelTime, range: NSRange(location: currentOffset, length: length))
            currentOffset += length
        }
        
        if ( hasCrank ) {
            
            length = MemoryLayout<UInt16>.size
            data.getBytes(&crank, range: NSRange(location: currentOffset, length: length))
            currentOffset += length
            
            length = MemoryLayout<UInt16>.size
            data.getBytes(&crankTime, range: NSRange(location: currentOffset, length: length))
            currentOffset += length
        }
        
        cumulativeWheel     = CFSwapInt32LittleToHost(wheel)
        lastWheelEventTime  = TimeInterval( Double(CFSwapInt16LittleToHost(wheelTime))/timeScale)
        cumulativeCrank     = CFSwapInt16LittleToHost(crank)
        lastCrankEventTime  = TimeInterval( Double(CFSwapInt16LittleToHost(crankTime))/timeScale)
    }
    
    func timeIntervalForCurrentSample(_ current: TimeInterval, previous: TimeInterval ) -> TimeInterval {
        var timeDiff: TimeInterval = 0
        if( current >= previous ) {
            timeDiff = current - previous
        }
        else {
            // passed the maximum value
            timeDiff =  (TimeInterval((Double( UINT16_MAX) / timeScale)) - previous) + current
        }
        return timeDiff
    }
    
    func valuesForPreviousMeasurement( previousSample: BluetoothSpeedAndCadenceDataPoint? ) -> ( cadenceinRPM:Double?, distanceinMeters:Double?, speedInMetersPerSecond:Double?)? {
        
        
        var distance:Double?, cadence:Double?, speed:Double?
        guard let previousSample = previousSample else {
            return nil
        }
        if ( hasWheel && previousSample.hasWheel ) {
            let wheelTimeDiff = timeIntervalForCurrentSample(lastWheelEventTime, previous: previousSample.lastWheelEventTime)
            
            let valueDiff = valueDiffForCurrentSample(cumulativeWheel, previous: previousSample.cumulativeWheel, max: UInt32.max)
            
            distance = Double( valueDiff * wheelSize) / 1000.0 // distance in meters
            if  distance != nil  &&  wheelTimeDiff > 0 {
                speed = (wheelTimeDiff == 0 ) ? 0 : distance! / wheelTimeDiff // m/s
            }
        }
        
        if( hasCrank && previousSample.hasCrank ) {
            let crankDiffTime = timeIntervalForCurrentSample(lastCrankEventTime, previous: previousSample.lastCrankEventTime)
            let valueDiff = Double(valueDiffForCurrentSample(cumulativeCrank, previous: previousSample.cumulativeCrank, max: UInt16.max))
            
            cadence = (crankDiffTime == 0) ? 0 : Double(60.0 * valueDiff / crankDiffTime) // RPM
        }
        print( "Cadence: \(cadence) RPM. Distance: \(distance) meters. Speed: \(speed) Km/h" )
        return ( cadenceinRPM:cadence, distanceinMeters:distance, speedInMetersPerSecond:speed)
    }
    
    var debugDescription:String {
        get {
            return "Wheel Revs: \(cumulativeWheel). Last wheel event time: \(lastWheelEventTime). Crank Revs: \(cumulativeCrank). Last Crank event time: \(lastCrankEventTime)"
        }
    }
}

extension BluetoothSpeedAndCadenceDataPoint {
    func valueDiffForCurrentSample(_ current: Double, previous: Double, max: Double) -> Double {
        var diff: Double = 0
        if  ( current >= previous ) {
            diff = current - previous
        }
        else {
            diff = ( max - previous ) + current
        }
        return diff
    }
    
    func valueDiffForCurrentSample(_ current: UInt32, previous: UInt32, max: UInt32) -> UInt32 {
        var diff: UInt32 = 0
        if  ( current >= previous ) {
            diff = current - previous
        }
        else {
            diff = ( max - previous ) + current
        }
        return diff
    }
    
    func valueDiffForCurrentSample(_ current: UInt16, previous: UInt16, max: UInt16) -> UInt16 {
        var diff: UInt16 = 0
        if  ( current >= previous ) {
            diff = current - previous
        }
        else {
            diff = ( max - previous ) + current
        }
        return diff
    }
}
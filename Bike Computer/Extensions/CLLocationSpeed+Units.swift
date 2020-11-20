//
//  CLLocationSpeed+Units.swift
//  Bike Computer
//
//  Created by Igor Kovryzhkin on 16.06.20.
//  Copyright © 2020 IgorK. All rights reserved.
//

import CoreLocation

// Сoefficient to convert Meters per Second into Kilometers per hour
private let mpsToKmph = 3.6

extension CLLocationSpeed {
    var kmph: CLLocationSpeed { return self * mpsToKmph }
}

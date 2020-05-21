//
//  GPSService.swift
//  Bike Computer
//
//  Created by Igor Kovryzhkin on 21.05.20.
//  Copyright © 2020 IgorK. All rights reserved.
//

import Foundation
import CoreLocation

protocol GPSSerivceProtocol {
    func requestUserAuthorization()
}

class GPSSerivce: NSObject, GPSSerivceProtocol {
    
    // MARK: - Private properties
    private let locationManager: CLLocationManager
    
    // MARK: - Constants
    private let desiredAccuracy = kCLLocationAccuracyBest
    
    // MARK: - Initializer
    init (locationManager: CLLocationManager = CLLocationManager()) {
        self.locationManager = locationManager
    }
    
    // MARK: - Public Properties
    
    func requestUserAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Private functions
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = desiredAccuracy
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
}

extension GPSSerivce: CLLocationManagerDelegate {
    
}

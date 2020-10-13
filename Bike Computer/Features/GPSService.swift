//
//  GPSService.swift
//  Bike Computer
//
//  Created by Igor Kovryzhkin on 21.05.20.
//  Copyright © 2020 IgorK. All rights reserved.
//

import Foundation
import CoreLocation
import Combine

protocol GPSSerivceProtocol {
    func requestUserAuthorizationIfNeeded()
    func startUpdatingLocation()
    var speed: Published<Double>.Publisher { get }
}

class GPSSerivce: NSObject, GPSSerivceProtocol {
    // MARK: - Public Propeties

    // Manually expose speed publisher
    var speed: Published<Double>.Publisher { $_speed }

    // MARK: - Private properties
    @Published private var _speed: Double = 0.0

    private let locationManager: CLLocationManager

    // MARK: - Constants
    private let desiredAccuracy = kCLLocationAccuracyBest
    private let distanceFilter = kCLDistanceFilterNone

    let minHorizontalAccuracyInMeters = 20.0
    let maxLocationAgeInSeconds = 10.0

    // MARK: - Initializer
    init (locationManager: CLLocationManager = CLLocationManager()) {
        self.locationManager = locationManager

        super.init()

        self.setupLocationManager()
    }

    // MARK: - Public Properties

    // FIXME: Need to restart after User Grants Permission
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        locationManager.requestLocation()
    }

    func requestUserAuthorizationIfNeeded() {
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - Private functions
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = desiredAccuracy
        locationManager.activityType = .fitness
        locationManager.distanceFilter = distanceFilter
    }
}

extension GPSSerivce: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let lastSpeed = locations.last?.speed,
            lastSpeed >= 0 // TODO: Negative Speed means invalid data. Add invalid data handling.
            else { return }

        self._speed = lastSpeed
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}

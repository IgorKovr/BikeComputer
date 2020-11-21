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

enum GPSSerivceError: Error {
    case locationUnknown
    case denied
    case unknown
}

protocol GPSSerivceProtocol {
    func requestUserAuthorizationIfNeeded()
    func stopUpdatingLocation()
    func startUpdatingLocation()
    var speed: Published<Result<Double, GPSSerivceError>>.Publisher { get }
}

class GPSSerivce: NSObject, GPSSerivceProtocol {
    // MARK: - Public Propeties

    // Manually expose speed publisher
    var speed: Published<Result<Double, GPSSerivceError>>.Publisher { $_speed }

    // MARK: - Private properties
    @Published private var _speed: Result<Double, GPSSerivceError> = .failure(.locationUnknown)

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

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
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
        guard let lastSpeed = locations.last?.speed, lastSpeed >= 0 else {
            _speed = .failure(.locationUnknown)
            return
        }

        self._speed = .success(lastSpeed)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Check if the error is CLError
        guard let coreLocationError = error as? CLError else {
            self._speed = .failure(.denied)
            print("CLLocationManager Failed with unknown error: \(error.localizedDescription) \n")
            return
        }

        // Switch CLError
        switch coreLocationError {
        case CLError.locationUnknown:
            self._speed = .failure(.locationUnknown)
        case CLError.denied:
            self._speed = .failure(.denied)
        default:
            self._speed = .failure(.unknown)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined, .denied, .restricted:
            self._speed = .failure(.denied)
        case .authorizedAlways, .authorizedWhenInUse:
            startUpdatingLocation()
            print("Location Usage Authorised")
        @unknown default:
            assertionFailure("Unknown CLAuthorizationStatus")
        }
    }
}


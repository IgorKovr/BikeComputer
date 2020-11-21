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
    case denied
    case unknown
}

protocol GPSSerivceProtocol {
    func requestUserAuthorizationIfNeeded()
    func stopUpdatingLocation()
    func startUpdatingLocation()
    var speed: PassthroughSubject<Double, GPSSerivceError> { get }
}

class GPSSerivce: NSObject, GPSSerivceProtocol {
    // MARK: - Public Propeties

    private(set) var speed = PassthroughSubject<Double, GPSSerivceError>()

    // MARK: - Private properties
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
            print("Couldn't read the location")
            return
        }

        speed.send(lastSpeed)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Check if the error is CLError
        guard let coreLocationError = error as? CLError else {
            speed.send(completion: .failure(.denied))
            print("CLLocationManager Failed with unknown error: \(error.localizedDescription) \n")
            return
        }

        // Switch CLError
        switch coreLocationError {
        case CLError.locationUnknown:
            print("Couldn't read the location")
        case CLError.denied:
            speed.send(completion: .failure(.denied))
        default:
            speed.send(completion: .failure(.unknown))
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined, .denied, .restricted:
            speed.send(completion: .failure(.denied))
        case .authorizedAlways, .authorizedWhenInUse:
            startUpdatingLocation()
            print("Location Usage Authorised")
        @unknown default:
            assertionFailure("Unknown CLAuthorizationStatus")
        }
    }
}

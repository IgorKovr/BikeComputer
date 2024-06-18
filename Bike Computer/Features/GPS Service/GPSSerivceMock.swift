//
//  GPSSerivceMock.swift
//  Bike Computer
//
//  Created by Igor Kovryzhkin on 18.06.24.
//  Copyright © 2024 IgorK. All rights reserved.
//

import Foundation
import Combine

class GPSSerivceMock: NSObject, GPSSerivceProtocol {
    // MARK: - Public Properties
    
    var speed: Published<Result<Double, GPSSerivceError>>.Publisher { $_speed }
    
    // MARK: - Private properties
    
    @Published private var _speed: Result<Double, GPSSerivceError> = .failure(.locationUnknown)
    private var timer: Timer?
    private var increasing: Bool = true
    
    // MARK: - Lifecycle
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Public Properties
    
    func requestUserAuthorizationIfNeeded() {}
    func stopUpdatingLocation() {}
    func startUpdatingLocation() {
        startTimer()
    }
    
    // MARK: - Private Properties
    
    private func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateSpeed), userInfo: nil, repeats: true)
    }
    
    @objc private func updateSpeed() {
        switch _speed {
        case .success(let currentSpeed):
            var newSpeed = currentSpeed
            if increasing {
                newSpeed += 1.0
                if newSpeed >= 30.0 {
                    increasing = false
                }
            } else {
                newSpeed -= 1.0
                if newSpeed <= 0.0 {
                    increasing = true
                }
            }
            _speed = .success(newSpeed)
        case .failure:
            _speed = .success(0.0)
        }
    }
}

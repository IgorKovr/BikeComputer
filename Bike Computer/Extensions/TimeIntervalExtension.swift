//
//  TimeIntervalExtension.swift
//  Bike Computer
//
//  Created by Igor Kovryzhkin on 19.06.20.
//  Copyright © 2020 IgorK. All rights reserved.
//

import Foundation

extension TimeInterval {

    func stringFormatted() -> String {
        let interval = Int(self)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 60 / 60) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

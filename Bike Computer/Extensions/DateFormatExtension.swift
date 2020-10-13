//
//  DateFormatExtension.swift
//  Bike Computer
//
//  Created by Igor Kovryzhkin on 27.05.20.
//  Copyright © 2020 IgorK. All rights reserved.
//

import Foundation

extension Date {
    func toString( dateFormat format: String ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}

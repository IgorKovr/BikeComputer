//
//  StringLocalizationExtension.swift
//  Bike Computer
//
//  Created by Igor Kovryzhkin on 27.05.20.
//  Copyright © 2020 IgorK. All rights reserved.
//

import Foundation

extension String {
    func localized(withComment comment: String? = nil) -> String {
        return NSLocalizedString(self, comment: comment ?? "")
    }
}

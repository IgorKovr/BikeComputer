//
//  AppSettingsHandler.swift
//  Bike Computer
//
//  Created by Igor Kovryzhkin on 20.11.20.
//  Copyright © 2020 IgorK. All rights reserved.
//

import UIKit

protocol AppSettingsHandling {
    func openAppSettings()
}

class AppSettingsHandler: AppSettingsHandling {

    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}

//
//  AlertView+AlertProvider.swift
//  Bike Computer
//
//  Created by Igor Kovryzhkin on 21.11.20.
//  Copyright © 2020 IgorK. All rights reserved.
//

import SwiftUI

extension Alert {
    init(_ alert: AlertProvider.Alert) {
        self.init(title: Text(alert.title),
                  message: Text(alert.message),
                  primaryButton: .default(Text(alert.primaryButtomText),
                                          action: alert.primaryButtonAction),
                  secondaryButton: .cancel())
    }
}

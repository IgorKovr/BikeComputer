//
//  AlertProvider.swift
//  Bike Computer
//
//  Created by Igor Kovryzhkin on 21.11.20.
//  Copyright © 2020 IgorK. All rights reserved.
//

import Foundation

class AlertProvider {
    struct Alert {
        var title: String
        let message: String
        let primaryButtomText: String
        let primaryButtonAction: () -> Void
    }

    @Published var shouldShowAlert = false

    var alert: Alert? = nil {
        didSet {
            shouldShowAlert = alert != nil
        }
    }
}

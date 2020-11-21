import Foundation
import Combine

class BikeComputerViewModel: ObservableObject {

    // MARK: - Public Properties

    @Published var shouldShowBTSpeed: Bool = false
    @Published var shouldShowGPSSpeed: Bool = false
    @Published var shouldShowHeartRate: Bool = false
    @Published var shouldShowCadence: Bool = false
    @Published var shouldShowAvarageSpeed: Bool = false
    @Published var shouldShowDistance: Bool = false

    @Published var gpsSpeed: String = ""
    @Published var heartRate: String = ""
    @Published var speedBT: String = ""
    @Published var cadence: String = ""
    @Published var averageSpeed: String = ""
    @Published var distance: String = ""
    @Published var curentSessionTime: String = ""

    var alertProvider = AlertProvider()

    // MARK: - Private Properties

    private var subscriptions = [AnyCancellable]()
    private let gpsService: GPSSerivceProtocol
    private let bluetoothSensor: BluetoothServiceProtocol
    private let appSettingsHandler: AppSettingsHandler

    private let sessionStartTimestamp: Date
    private var curentSessionTimeInterval: TimeInterval = 1

    // MARK: - Initializer

    init(gpsService: GPSSerivceProtocol = GPSSerivce(),
         bluetoothSensor: BluetoothService = BluetoothService(),
         appSettingsHandler: AppSettingsHandler = AppSettingsHandler()) {
        self.gpsService = gpsService
        self.bluetoothSensor = bluetoothSensor
        self.appSettingsHandler = appSettingsHandler
        sessionStartTimestamp = Date()

        setupTimer()
        startGpsService()

        bluetoothSensor.startBluetoothScan()
        startObservingBluetoothSensor()
    }

    // MARK: - Private Functions

    private func startObservingBluetoothSensor() {
        bluetoothSensor.heartRate
            .map { [weak self] in
                self?.shouldShowHeartRate = ($0 != 0)
                return String(format: "\($0)")
            }
            .assign(to: \.heartRate, on: self)
            .store(in: &subscriptions)

        bluetoothSensor.speedInMetersPerSecond
            .map { [weak self] in
                self?.shouldShowBTSpeed = !$0.isZero
                self?.shouldShowGPSSpeed = $0.isZero
                return String(format: "%.1f", $0.kmph)
            }
            .assign(to: \.speedBT, on: self)
            .store(in: &subscriptions)

        bluetoothSensor.cadence
            .map { [weak self] in
                self?.shouldShowCadence = !$0.isZero
                return String(format: "%.f", $0.rounded())
            }
            .assign(to: \.cadence, on: self)
            .store(in: &subscriptions)

        bluetoothSensor.distanceInMeters
            .map { [weak self] in
                self?.shouldShowDistance = !$0.isZero
                return String(format: "%.f", $0.rounded())
            }
            .assign(to: \.distance, on: self)
            .store(in: &subscriptions)

        bluetoothSensor.distanceInMeters
            .map { [weak self] in
                self?.shouldShowAvarageSpeed = !$0.isZero

                guard let interval = self?.curentSessionTimeInterval,
                      !interval.isZero else {
                    return "0"
                }

                return String(format: "%.f", ($0 / interval).kmph)
            }
            .assign(to: \.averageSpeed, on: self)
            .store(in: &subscriptions)
    }

    private func setupTimer() {
        let publisher = Timer.TimerPublisher(interval: 1.0, runLoop: .main, mode: .default).autoconnect()
        let subscription = publisher
            .map { date in
                self.curentSessionTimeInterval = date.timeIntervalSince(self.sessionStartTimestamp)
                return "\(self.curentSessionTimeInterval.stringFormatted())"
        }
            .assign(to: \.curentSessionTime, on: self)
        subscriptions.append(subscription)
    }
}

// MARK: - GPS Handling
private extension BikeComputerViewModel {

    private func startGpsService() {
        gpsService.requestUserAuthorizationIfNeeded()
        gpsService.startUpdatingLocation()

        gpsService.speed
            .sink { [weak self] in
                switch $0 {
                case let .success(speed): self?.receiveGPSValue(speed)
                case let .failure(error): self?.receiveGPSError(error)
                }
            }

            .store(in: &subscriptions)
    }

    private func receiveGPSError(_ error: GPSSerivceError) {
        shouldShowGPSSpeed = false

        switch error {
        case .locationUnknown:
            print("Couldn't read the location")
            // Only show GPS speed if the BT Speed is not available
            if shouldShowBTSpeed == false {
                shouldShowGPSSpeed = true
            }

            gpsSpeed = "-"
        case .denied:
            print("Location services denied")
            onLocationDeniedReceived()
        case .unknown:
            print("Unknown Location services Error")
        }
    }

    private func receiveGPSValue(_ speed: Double) {
        // Only show GPS speed if the BT Speed is not available
        if shouldShowBTSpeed == false {
            shouldShowGPSSpeed = true
        }
        gpsSpeed = String(format: "%.1f", speed.kmph)
    }

    private func onLocationDeniedReceived() {
        alertProvider.alert = AlertProvider.Alert(
            title: "Location Service is disabled",
            message: #"Set it to "While using the App" in the settings"#,
            primaryButtomText: "Ok",
            primaryButtonAction: { [weak self] in
                self?.appSettingsHandler.openAppSettings()
            }
        )

        gpsService.stopUpdatingLocation()
    }
}

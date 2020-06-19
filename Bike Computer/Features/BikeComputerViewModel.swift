import Foundation
import Combine

class BikeComputerViewModel: ObservableObject {
    
    // MARK: - Public Properties
    
    @Published var speed: String = ""
    @Published var heartRate: String = ""
    @Published var speedBT: String = ""
    @Published var cadence: String = ""
    @Published var averageSpeed: String = ""
    @Published var distance: String = ""
    @Published var curentSessionTime: String = ""
    
    // MARK: - Private Properties
    
    private var subscriptions = [AnyCancellable]()
    private let gpsService: GPSSerivceProtocol
    private let bluetoothSensor: BluetoothServiceProtocol
    
    private let sessionStartTimestamp: Date
    private var curentSessionTimeInterval: TimeInterval = 0
    
    // MARK: - Initializer
    
    init(gpsService: GPSSerivceProtocol = GPSSerivce(),
         bluetoothSensor: BluetoothService = BluetoothService()) {
        self.gpsService = gpsService
        self.bluetoothSensor = bluetoothSensor
        sessionStartTimestamp = Date()
        
        setupTimer()
        gpsService.requestUserAuthorizationIfNeeded()
        gpsService.startUpdatingLocation()
        startObservingGpsService()
        
        bluetoothSensor.startBluetoothScan()
        startObservingBluetoothSensor()
    }
    
    // MARK: - Private Functions
    
    private func startObservingBluetoothSensor() {
        bluetoothSensor.heartRate
            .map { String(format: "\($0)") }
            .assign(to: \.heartRate, on: self)
            .store(in: &subscriptions)
        
        bluetoothSensor.speedInMetersPerSecond
            .map { String(format: "%.1f", $0.kmph) }
            .assign(to: \.speedBT, on: self)
            .store(in: &subscriptions)
        
        bluetoothSensor.cadence
            .map { String(format: "\($0)") }
            .assign(to: \.cadence, on: self)
            .store(in: &subscriptions)
        
        bluetoothSensor.distanceInMeters
            .map { String(format: "%.f", $0.rounded()) }
            .assign(to: \.distance, on: self)
            .store(in: &subscriptions)
        
        bluetoothSensor.distanceInMeters
            .map { String(format: "%.f", ($0 / self.curentSessionTimeInterval).kmph) }
            .assign(to: \.averageSpeed, on: self)
            .store(in: &subscriptions)
    }
    
    private func startObservingGpsService() {
        gpsService.speed
            .map { String(format: "%.1f", $0.kmph) }
            .assign(to: \.speed, on: self)
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

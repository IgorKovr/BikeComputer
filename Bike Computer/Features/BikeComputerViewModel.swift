import Foundation
import Combine

class BikeComputerViewModel: ObservableObject {
    
    // MARK: - Public Properties
    
    @Published var speed: String = ""
    @Published var heartRate: String = ""
    @Published var time: String = ""
    @Published var speedBT: String = ""
    @Published var cadence: String = ""
    
    // MARK: - Private Properties
    
    private var subscriptions = [AnyCancellable]()
    private let gpsService: GPSSerivceProtocol
    private let bluetoothSensor: BluetoothServiceProtocol
    
    // MARK: - Initializer
    
    init(gpsService: GPSSerivceProtocol = GPSSerivce(),
         bluetoothSensor: BluetoothService = BluetoothService()) {
        self.gpsService = gpsService
        self.bluetoothSensor = bluetoothSensor
        
        setupSpeedTimer()
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
        
        bluetoothSensor.speed
            .map { String(format: "\($0)") }
            .assign(to: \.speedBT, on: self)
            .store(in: &subscriptions)
        
        bluetoothSensor.cadence
            .map { String(format: "\($0)") }
            .assign(to: \.cadence, on: self)
            .store(in: &subscriptions)
    }
    
    private func startObservingGpsService() {
        gpsService.speed
            .map { String(format: "%.1f", $0.kmph) }
            .assign(to: \.speed, on: self)
            .store(in: &subscriptions)
    }
    
    private func setupSpeedTimer() {
        let publisher = Timer.TimerPublisher(interval: 1.0, runLoop: .main, mode: .default).autoconnect()
        let subscription = publisher
            .map { date in return "\(date.toString(dateFormat: "hh:mm:ss"))" }
            .assign(to: \.time, on: self)
        subscriptions.append(subscription)
    }
}

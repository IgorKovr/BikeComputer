import Foundation
import Combine

class BikeComputerViewModel: ObservableObject {
    
    @Published var speed: String = ""
    @Published var heartRate: String = ""
    @Published var time: String = ""
    
    private var subscriptions = [AnyCancellable]()
    
    private let gpsService: GPSSerivceProtocol
    private let bluetoothSensor: BluetoothService
    
    init(gpsService: GPSSerivceProtocol = GPSSerivce(),
         bluetoothSensor: BluetoothService = BluetoothService()) {
        self.gpsService = gpsService
        self.bluetoothSensor = bluetoothSensor
        
        setupSpeedTimer()
        gpsService.requestUserAuthorizationIfNeeded()
        gpsService.startUpdatingLocation()
        startObservingGpsService()
        
        bluetoothSensor.start()
        startObservingBluetoothSensor()
    }
    
    private func startObservingBluetoothSensor() {
        bluetoothSensor.heartRate
            .map { String(format: "\($0)") }
            .assign(to: \.heartRate, on: self)
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

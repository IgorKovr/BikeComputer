import Foundation
import Combine

class BikeComputerViewModel: ObservableObject {
  
  @Published var speed: String = ""
  @Published var time: String = ""
  
  private var subscriptions = [AnyCancellable]()
  
  private let gpsService: GPSSerivceProtocol
  
  init(gpsService: GPSSerivceProtocol = GPSSerivce()) {
    self.gpsService = gpsService
    
    setupSpeedTimer()
    askForLocationAccessIfNeeded()
  }
  
  private func startObservingGpsService() {
    gpsService.speed
      .map{ String($0) }
      .assign(to: \.speed, on: self)
      .store(in: &subscriptions)
  }
  
  private func setupSpeedTimer() {
    let publisher = Timer.TimerPublisher(interval: 1.0, runLoop: .main, mode: .default).autoconnect()
    let subscription = publisher
      .map { date in return "\(date)" }
      .assign(to: \.time, on: self)
    subscriptions.append(subscription)
  }
  
  private func askForLocationAccessIfNeeded() {
    gpsService.requestUserAuthorizationIfNeeded()
  }
}

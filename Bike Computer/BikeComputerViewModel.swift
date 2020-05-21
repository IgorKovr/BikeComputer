import Foundation
import Combine

class BikeComputerViewModel: ObservableObject {
  
  @Published var speed: String = ""
  
  private var subscriptions = [AnyCancellable]()
  
  init() {
    setupSpeedTimer()
  }
  
  private func setupSpeedTimer() {
    
    let publisher = Timer.TimerPublisher(interval: 1.0, runLoop: .main, mode: .default).autoconnect()
    let subscription = publisher
      .map { date in return "\(date)" }
      .assign(to: \.speed, on: self)
    subscriptions.append(subscription)
  }
}

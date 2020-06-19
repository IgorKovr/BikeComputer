import SwiftUI

struct BikeComputerView: View {
    
    @ObservedObject var viewModel = BikeComputerViewModel()
    
    var body: some View {
        VStack {
            Group {
                Text("🏎")
                    .font(.system(size: 40))
                Text(viewModel.speedBT)
                    .font(.system(size: 80, design: .monospaced))
                    .frame(maxWidth: .infinity)
            }
            Group {
                Text("🛰")
                    .font(.system(size: 40))
                Text(viewModel.speed)
                    .font(.system(size: 80, design: .monospaced))
                    .frame(maxWidth: .infinity)
            }
            Group {
                Text("❤️")
                    .font(.system(size: 25))
                Text(viewModel.heartRate)
                    .font(.system(size: 60, design: .monospaced))
                    .frame(maxWidth: .infinity)
            }
//            Group {
//                Spacer()
//                    .frame(height: 30)
//                Text(viewModel.cadence)
//                    .font(.system(size: 80.0, design: .monospaced))
//                    .frame(maxWidth: .infinity)
//            }
            Group {
                Text("🛣")
                    .font(.system(size: 25))
                Text(viewModel.distance)
                    .font(.system(size: 60, design: .monospaced))
                    .frame(maxWidth: .infinity)
            }
            Group {
                Text("🗺")
                    .font(.system(size: 25))
                Text(viewModel.averageSpeed)
                    .font(.system(size: 60, design: .monospaced))
                    .frame(maxWidth: .infinity)
            }
            Group {
                Text("⏱")
                    .font(.system(size: 25))
                Text(viewModel.curentSessionTime)
                    .font(.system(size: 60, design: .monospaced))
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        BikeComputerView()
    }
}

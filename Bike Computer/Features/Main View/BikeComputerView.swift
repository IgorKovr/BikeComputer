import SwiftUI

struct BikeComputerView: View {

    @ObservedObject var viewModel = BikeComputerViewModel()

    var body: some View {
        VStack {
            if viewModel.shouldShowBTSpeed {
                Group {
                    Text("🏎")
                        .font(.system(size: 40))
                    Text(viewModel.speedBT)
                        .font(.system(size: 80, design: .monospaced))
                        .frame(maxWidth: .infinity)
                }
            }
            if viewModel.shouldShowGPSSpeed {
                Group {
                    Text("🛰")
                        .font(.system(size: 40))
                    Text(viewModel.gpsSpeed)
                        .font(.system(size: 80, design: .monospaced))
                        .frame(maxWidth: .infinity)
                }
            }
            if viewModel.shouldShowHeartRate {
                Group {
                    Text("❤️")
                        .font(.system(size: 25))
                    Text(viewModel.heartRate)
                        .font(.system(size: 60, design: .monospaced))
                        .frame(maxWidth: .infinity)
                }
            }
            if viewModel.shouldShowCadence {
                Group {
                    Text("Cadence")
                        .font(.system(size: 25))
                    Text(viewModel.cadence)
                        .font(.system(size: 80.0, design: .monospaced))
                        .frame(maxWidth: .infinity)
                }
            }
            if viewModel.shouldShowDistance {
                Group {
                    Text("🛣")
                        .font(.system(size: 25))
                    Text(viewModel.distance)
                        .font(.system(size: 60, design: .monospaced))
                        .frame(maxWidth: .infinity)
                }
            }
            if viewModel.shouldShowAvarageSpeed {
                Group {
                    Text("🗺")
                        .font(.system(size: 25))
                    Text(viewModel.averageSpeed)
                        .font(.system(size: 60, design: .monospaced))
                        .frame(maxWidth: .infinity)
                }
            }
            Group {
                Text("⏱")
                    .font(.system(size: 25))
                Text(viewModel.curentSessionTime)
                    .font(.system(size: 60, design: .monospaced))
                    .frame(maxWidth: .infinity)
            }
        }
        .alert(isPresented: $viewModel.alertProvider.shouldShowAlert ) {
            guard let alert = viewModel.alertProvider.alert else {
                fatalError("Alert not available")
            }

            return Alert(alert)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        BikeComputerView()
    }
}

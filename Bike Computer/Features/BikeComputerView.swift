import SwiftUI

struct BikeComputerView: View {
    
    @ObservedObject var viewModel = BikeComputerViewModel()
    
    var body: some View {
        VStack {
            Text(viewModel.speed)
                .font(.system(size: 80.0, design: .monospaced))
                .frame(maxWidth: .infinity)
            Spacer()
                .frame(height: 30)
            Text(viewModel.time)
                .font(.system(size: 60.0, design: .monospaced))
                .frame(maxWidth: .infinity)
            Spacer()
                .frame(height: 30)
            Text(viewModel.heartRate)
                .font(.system(size: 80.0, design: .monospaced))
                .frame(maxWidth: .infinity)
            Spacer()
                .frame(height: 30)
            Text(viewModel.speedBT)
                .font(.system(size: 80.0, design: .monospaced))
                .frame(maxWidth: .infinity)
            Spacer()
                .frame(height: 30)
            Text(viewModel.cadence)
                .font(.system(size: 80.0, design: .monospaced))
                .frame(maxWidth: .infinity)
        }.animation(.easeInOut)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        BikeComputerView()
    }
}

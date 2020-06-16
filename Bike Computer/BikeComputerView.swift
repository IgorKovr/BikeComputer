import SwiftUI

struct BikeComputerView: View {
    
    @ObservedObject var viewModel = BikeComputerViewModel()
    
    var body: some View {
        VStack {
            Text(viewModel.speed)
                .font(.system(size: 100.0))
                .frame(maxWidth: .infinity)
            Text(viewModel.time)
                .font(.system(size: 60.0))
                .frame(maxWidth: .infinity)
        }.animation(.easeInOut)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        BikeComputerView()
    }
}

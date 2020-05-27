import SwiftUI

struct BikeComputerView: View {
  
  @ObservedObject var viewModel = BikeComputerViewModel()
  
  var body: some View {
    VStack {
        Text(viewModel.speed)
        Text(viewModel.time)
    }.animation(.easeInOut)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    BikeComputerView()
  }
}

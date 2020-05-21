import SwiftUI

struct BikeComputerView: View {
  
  @ObservedObject var viewModel = BikeComputerViewModel()
  
  var body: some View {
    Text(viewModel.speed)
      .animation(.easeInOut)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    BikeComputerView()
  }
}

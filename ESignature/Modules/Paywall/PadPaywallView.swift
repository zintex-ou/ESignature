
import SwiftUI

struct PadPaywallView: View {
    
    @StateObject var viewModel: PaywallViewModel
    @State private var isPresented: Bool = true

    var body: some View {
        ZStack {
            Color.black
                .opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            PaywallView(viewModel: viewModel)
                .frame(width: 519, height: 784)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            
        }
    }
}


import SwiftUI

struct PadPaywallView: View {
    
    @StateObject var viewModel: PaywallViewModel
    @State private var isPresented: Bool = true

    var body: some View {
        Color.black
            .opacity(0.5)
            .edgesIgnoringSafeArea(.all)
            .transparentFullScreenCover(isPresented: $isPresented, cornerRadius: 24) {
                PaywallView(viewModel: viewModel)
                    .frame(width: 519, height: 768)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
    }
}

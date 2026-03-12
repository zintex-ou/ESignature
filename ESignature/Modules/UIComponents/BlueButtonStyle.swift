
import SwiftUI

struct BlueButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom(R.font.outfitSemiBold, size: 16))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(.c0666EB)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
    
}


import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        Image(systemName: "square.and.arrow.down.on.square")
            .resizable()
            .frame(width: UIScreen.main.bounds.width / 5, height: UIScreen.main.bounds.width / 5)
            .clipShape(RoundedRectangle(cornerRadius: (UIScreen.main.bounds.width / 5) / 4))
    }
}

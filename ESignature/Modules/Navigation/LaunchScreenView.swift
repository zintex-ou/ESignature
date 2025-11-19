import SwiftUI

struct LaunchScreenView: View {
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            Image(.launch)
                .resizable()
                .scaledToFill()
                .frame(width: 90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

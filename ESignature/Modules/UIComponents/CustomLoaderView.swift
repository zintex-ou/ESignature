
import SwiftUI

struct CustomLoaderView: View {
    var body: some View {
        ZStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .c4D22B2))
                .scaleEffect(2.0)
                .frame(width: 150, height: 150)
//                .offset(y: 10)
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

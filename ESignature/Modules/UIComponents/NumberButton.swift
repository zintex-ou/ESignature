
import SwiftUI

struct NumberButton: View {
    let title: String
    let fontSize: CGFloat
    let action: () -> Void
    
    init(title: String, fontSize: CGFloat = 24, action: @escaping () -> Void) {
        self.title = title
        self.fontSize = fontSize
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom(R.font.onestLight, size: 36))
                .foregroundColor(.black)
                .frame(width: 74, height: 74)
                .background(Color.white)
                .clipShape(Circle())
        }
    }
}

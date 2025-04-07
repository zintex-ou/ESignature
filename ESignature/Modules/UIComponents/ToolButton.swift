
import SwiftUI

struct ToolButton: View {
    let icon: UIImage?
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(uiImage: icon ?? UIImage())
                    .frame(width: 24, height: 24)
                
                Text(label)
                    .font(.custom(R.font.outfitSemiBold, size: 12))
                    .foregroundColor(.black)
            }
        }
    }
}


import SwiftUI

struct SettingsNavBar: View {
    
    let title: String
    
    let action: () -> Void
    
    var body: some View {
        ZStack {
            HStack {
                Button {
                    action()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.c191919)
                        .frame(width: 24, height: 24)
                }
                
                Spacer()
            }
            Text(title)
                .font(.custom(R.font.outfitSemiBold, size: 16))
        }
    }
}

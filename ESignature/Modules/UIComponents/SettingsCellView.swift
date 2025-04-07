
import SwiftUI

struct SettingsCellView: View {
    
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.custom(R.font.onestLight, size: 16))
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.c7C7C7C)
                .frame(width: 24, height: 24)
            
    
        }
        .padding(.horizontal, 16)
    }
}


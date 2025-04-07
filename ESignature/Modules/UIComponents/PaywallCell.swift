
import SwiftUI

struct PaywallCell: View {
    let title: String
    let price: String
    let currency: String
    let period: String
    let selected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(selected ? R.image.selectedPaywall : R.image.unselectedPaywall)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .padding(.leading, 16)
                
                Text(title)
                    .font(.custom(R.font.outfitSemiBold, size: 14))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(price)\(currency)/\(period)")
                    .font(.custom(R.font.outfitRegular, size: 14))
                    .foregroundStyle(.white)
                    .opacity(0.5)
                    .padding(.trailing, 16)
            }
            .frame(height: 46)
            .background(.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .inset(by: 0.5)
                    .stroke(.white.opacity(selected ? 1 : 0.5), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
}


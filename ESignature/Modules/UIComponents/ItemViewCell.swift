import SwiftUI

struct ItemViewCell: View {
    private let sign: OverlaysModel
    private let isSelected: Bool
    
    init(sign: OverlaysModel, isSelected: Bool = false) {
        self.sign = sign
        self.isSelected = isSelected
    }
    
    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometryProxy in
                ZStack(alignment: .topTrailing) {
                    if let uiImage = sign.image {

                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometryProxy.size.width, height: geometryProxy.size.width)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                    }
                    
                    if isSelected {
                            ZStack {
                                Image(R.image.selecItemIcon)
                                    .resizable()
                                    .frame(width: 18, height: 18)
                            }
                            .offset(x: -12, y: 12)
                        
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(width: 164, height: 160)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? .c0666EB : Color.clear, lineWidth: 2)
            )
            
            Text(sign.name)
                .font(.custom(R.font.outfitSemiBold, size: 14))
                .foregroundStyle(.black)
                .lineLimit(1)
        }
   
    }
}

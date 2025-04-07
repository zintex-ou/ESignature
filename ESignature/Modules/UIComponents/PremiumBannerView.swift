
import SwiftUI

struct PremiumBannerView: View {
    
    private let isPad = UIDevice.current.userInterfaceIdiom == .pad
    
    private enum Constants {
        static var premBannerPad = { R.image.premBannerPad }
        static var premBannerPhone = { R.image.premBannerPhone }
        static var penImagePad = { R.image.penImagePad }
        static var penImagePhone = { R.image.penImagePhone }
    }
    
    var body: some View {
        ZStack {
            Image(isPad ? Constants.premBannerPad() : Constants.premBannerPhone())
                .resizable()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    HStack {
                       if isPad {
                           HStack(spacing: 16) {
                                Text(R.string.localizable.unlockESignature())
                                    .font(.custom(R.font.outfitSemiBold, size: 20))
                                    .foregroundStyle(.white)
                                
                                ZStack {
                                    Text(R.string.localizable.upgrade())
                                        .font(.custom(R.font.outfitSemiBold, size: 14))
                                        .foregroundStyle(.black)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 24))

                            }
                        } else {
                            VStack(alignment: .leading) {
                                Text(R.string.localizable.unlockESignature())
                                    .font(.custom(R.font.outfitSemiBold, size: 20))
                                    .foregroundStyle(.white)
                                
                                ZStack {
                                    Text(R.string.localizable.upgrade())
                                        .font(.custom(R.font.outfitSemiBold, size: 14))
                                        .foregroundStyle(.black)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 24))


                            }
                        }
                       
                        Spacer()
                        
                        VStack {
                            Spacer()
                            Image(isPad ? Constants.penImagePad() : Constants.penImagePhone())
                                .padding(.trailing, isPad ? 24 : 6)
                        }
                        
                    }
                    .padding(.leading, isPad ? 24 : 16)
                    
                }
            
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}


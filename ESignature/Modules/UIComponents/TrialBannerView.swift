
import SwiftUI

struct TrialBannerView: View {
    let title: String
    
    var body: some View {
        Button {
        } label: {
            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    Text(R.string.localizable.bannerText())
                        .font(.custom(R.font.ltWaveBold, size: 16))
                        .minimumScaleFactor(0.3)
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 66))
    }
}

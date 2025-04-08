
import SwiftUI

struct CustomSearchBar: View {
    @Binding var text: String
    var placeholder: String = R.string.localizable.search()
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(R.image.searchLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                
                TextField(placeholder, text: $text)
                    .foregroundColor(.black)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.none)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(.cE5E5E5)
            .cornerRadius(24)

            if !text.isEmpty {
                Button() {
                    text = ""
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                    to: nil,
                                                    from: nil,
                                                    for: nil)
                } label: {
                    Text(R.string.localizable.cancel())
                        .foregroundStyle(.c0666EB)
                        .font(.custom(R.font.outfitSemiBold, size: 16))
                }
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.default, value: text)
    }
}


import SwiftUI

struct AuthView: View {
    
    @StateObject var viewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            VStack {
                SettingsNavBar(title: R.string.localizable.authentication()) {
                    viewModel.pop()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                VStack(spacing: 16) {
                    
                    VStack(spacing: 10) {
                        ForEach(AuthEnum.allCases, id: \.self) { item in
                            AuthCellView(
                                viewModel: viewModel,
                                title: item.title,
                                timeInfo: viewModel.seconds,
                                toggleable: item.toggleable,
                                hasInfo: item.hasInfo
                            )
                            .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.handleTap(on: item)
                                }
                            
                            Divider()
                                .background(.cE5E5E5)
                                .frame(height: 0.5)
                                .offset(y: 1)
                        }
                    }
                    .padding(.top, 12)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Spacer()
                }
                .padding(.top, 24)
                .padding(.horizontal, 16)
                
            }
            .background(.cF7F7F7)
        }
    }
}

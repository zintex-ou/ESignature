
import SwiftUI

struct SettingsView: View {
    
    @StateObject var viewModel: SettingsViewModel
    
    var body: some View {
        ZStack {
            VStack {
                SettingsNavBar(title: R.string.localizable.settings()) {
                    viewModel.pop()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                VStack(spacing: 16) {
                    if !viewModel.checkPremium() {
                        PremiumBannerView()
                            .frame(height: 126)
                    }
                    
                    VStack(spacing: 10) {
                        ForEach(SettingsEnum.allCases, id: \.self) { item in
                            SettingsCellView(
                                title: item.title
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
        .alert(isPresented: $viewModel.showAlert) {
            return Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"), action: {
                })
            )
        }
    }
    
}


import SwiftUI
import Lottie

struct PaywallView: View {
    
    @StateObject var viewModel: PaywallViewModel
    
    @State private var closeIsVisible = false
    
    private let isPad = UIDevice.current.userInterfaceIdiom == .pad
    
    var body: some View {
        ZStack {
            Image(isPad ? R.image.onboardBackPad : R.image.onboardBackPhone)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                CustomLoaderView()
            }
            
            navBar
            
            VStack {
                Spacer()
                
                LottieView(animation: .named("paywallAnimation"))
                    .looping()
                    .resizable()
                    .clipped()
                    .scaledToFit()
                    .scaleEffect(1)
                
                Spacer()
                
                textStack
                
                ForEach(viewModel.paywallProducts) { product in
                    PaywallCell(
                        title: product.nameProduct,
                        price: "\(product.price)",
                        currency: product.currency,
                        period: product.timePeriod,
                        selected: product.isSelected) {
                            viewModel.selectPaywallProduct(product: product)
                        }
                        .padding(.vertical, 4)
                }
                                
                Button {
                    viewModel.tapOnContinue {
                        viewModel.dissmis()
                    }
                } label: {
                    if viewModel.reviewStatus() {
                        Text(viewModel.continueButtonText(adaptyProduct: viewModel.selectedProduct!))
                            .font(.custom(R.font.outfitSemiBold, size: 16))
                            .foregroundStyle(.c191919)
                    } else {
                        
                        Text(R.string.localizable.continue())
                            .font(.custom(R.font.outfitSemiBold, size: 16))
                            .foregroundStyle(.c191919)
                    }
             
                }
                .buttonStyle(OnboardButtonStyle())
                .padding(.bottom, 40)
                .pulseButtonStyle(isAnimated: !viewModel.reviewStatus())
                
                termsAndPrivacyStack
            }
            .padding(.horizontal, 16)
        }
    }
    
    @ViewBuilder
    private var textStack: some View {
        VStack(spacing: 8) {
            Text(R.string.localizable.unlockFullAccess())
                .font(.custom(R.font.outfitSemiBold, size: 24))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(.white)
            
            Text(R.string.localizable.signShareAddStampsWatermarks699WeekWith3DayFreeTrial())
                .font(.custom(R.font.outfitRegular, size: 16))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(.white)
                .opacity(viewModel.reviewStatus() ? 1 : 0.5)
        }
    }
    
    
    @ViewBuilder
    private var termsAndPrivacyStack: some View {
        HStack {
            Text(R.string.localizable.byContinuingYouAgreeToThe())
                .font(.custom(R.font.outfitRegular, size: 12))
                .lineLimit(3)
                .minimumScaleFactor(0.5)
                .foregroundColor(.c8082A8)
            
            Text(R.string.localizable.privacyPolicy())
                .font(.custom(R.font.outfitRegular, size: 12))
                .foregroundColor(.c8082A8)
                .underline()
                .onTapGesture {
                    viewModel.openPrivacyPolicy()
                }
            
            Text("&")
                .font(.custom(R.font.outfitRegular, size: 11))
                .foregroundColor(.c8082A8)
            
            
            Text(R.string.localizable.termOfUse())
                .font(.custom(R.font.outfitRegular, size: 12))
                .foregroundColor(.c8082A8)
                .underline()
                .onTapGesture {
                    viewModel.openTermsOfUse()
                }
        }
    }
    
    @ViewBuilder
    private var navBar: some View {
        VStack {
            HStack {
                Button {
                    viewModel.dissmis()
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .foregroundColor(.white)
                        .opacity(closeIsVisible ? 0.5 : 0)
                        .animation(.easeInOut(duration: 5), value: closeIsVisible)
                        .onAppear {
                            closeIsVisible = true
                        }
                        .frame(width: 16, height: 16)
                }
                
                Spacer()
                
                Text(R.string.localizable.restore())
                    .font(.custom(R.font.outfitRegular, size: 16))
                    .foregroundColor(.white)
                    .opacity(0.5)
                    .onTapGesture {
                        viewModel.tapOnRestore {
                            viewModel.dissmis()
                        }
                        
                    }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            Spacer()
        }
        .zIndex(1)
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

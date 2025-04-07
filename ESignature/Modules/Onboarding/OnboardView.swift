
import SwiftUI
import Lottie

struct OnboardView: View {
    
    @StateObject var viewModel: OnboardViewModel
    
    @State var currentPage: Int = 0
    var maxPages = 5
    
    private let isPad = UIDevice.current.userInterfaceIdiom == .pad
    
    @State private var closeIsVisible = false
    
    private let phoneImage: [UIImage] = [
        R.image.onboardPhone1() ?? UIImage(),
        R.image.onboardPhone2() ?? UIImage(),
        R.image.onboardPhone3() ?? UIImage(),
        R.image.onboardPhone4() ?? UIImage(),
        R.image.onboardPhone5() ?? UIImage()
    ]
    
    private let padImage: [UIImage] = [
        R.image.onboardPad1() ?? UIImage(),
        R.image.onboardPad2() ?? UIImage(),
        R.image.onboardPad3() ?? UIImage(),
        R.image.onboardPad5() ?? UIImage(),
        R.image.onboardPad5() ?? UIImage(),
    ]
    
    private let title: [String] = [
        R.string.localizable.titleOnboard1(),
        R.string.localizable.titleOnboard2(),
        R.string.localizable.titleOnboard3(),
        R.string.localizable.titleOnboard4(),
        R.string.localizable.titleOnboard5()
    ]
    
    private let desc: [String] = [
        R.string.localizable.descOnboard1(),
        R.string.localizable.descOnboard2(),
        R.string.localizable.descOnboard3(),
        R.string.localizable.descOnboard4(),
        R.string.localizable.descOnboard5()
    ]
    
    var body: some View {
        ZStack(alignment: .top) {

            if currentPage == 4 {
                navBar
            }
            
            VStack {
                Spacer()
                
                switch currentPage {
                case 3:
                    LottieView(animation: .named(isPad ? "stampPadAnimation" : "stampPhoneAnimation"))
                        .looping()
                        .resizable()
                        .clipped()
                        .scaledToFit()
                        .scaleEffect(1.2)
                    
                case 4:
                    Image(uiImage: isPad ? padImage[currentPage] : phoneImage[currentPage])
                        .resizable()
                        .scaledToFit()
                default:
                    Image(uiImage: isPad ? padImage[currentPage] : phoneImage[currentPage])
                        .resizable()
                        .scaledToFit()
                }
                
                Spacer()
                
                CustomPageControl(currentPage: $currentPage, totalPages: 6)
                    .padding(.bottom, 16)
                
                textStack
                    .padding(.bottom, 16)
                    .padding(.horizontal, 16)
                
                continueButton
            }
            
            VStack {
                Spacer()
                
                if currentPage == 4 {
                    termsAndPrivacyStack
                }
            }
        }
        .alert(isPresented: $viewModel.showAlert) {
            return Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"), action: {
                })
            )
        }
        .background { 
            Image(isPad ? R.image.onboardBackPad : R.image.onboardBackPhone)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea(.all)
                .scaleEffect(1.05)
        }
    }
    
    @ViewBuilder
    private var textStack: some View {
        VStack(spacing: 8) {
            Text(title[currentPage])
                .font(.custom(R.font.outfitSemiBold, size: 24))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(.white)
            
            Text(desc[currentPage])
                .font(.custom(R.font.outfitRegular, size: 16))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(.white)
                .opacity(0.5)
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
        ZStack {
            HStack {
                Button {
                    viewModel.onComplete()
                } label: {
                    if viewModel.reviewStatus() {
                        Image(systemName: "xmark")
                            .resizable()
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                        
                    } else {
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
                    
                }
                Spacer()
            }
  
                
            HStack {
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

            

        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .zIndex(1)
    }
    
    @ViewBuilder
    private var continueButton: some View {
        Button {
            if currentPage < 4 {
                currentPage += 1
                if !viewModel.reviewStatus() {
                    if currentPage == 1 {
                        viewModel.requestReview()
                    }
                }
            } else {
                Task {
                    await tapOnContinue {
                        viewModel.onComplete()
                    }
                }
            }
        } label: {
            if currentPage < 4 {
                Text(R.string.localizable.continue())
                .font(.custom(R.font.outfitSemiBold, size: 16))
            } else {
                Text(
                    viewModel.reviewStatus() ? String(localized: viewModel.getSubtitle())
                    : R.string.localizable.continue()
                )
                .font(.custom(R.font.outfitSemiBold, size: 16))
            }
        }
        .buttonStyle(OnboardButtonStyle())
        .padding(.horizontal, 16)
        .padding(.bottom, 40)
        .pulseButtonStyle(isAnimated: !viewModel.reviewStatus())
    }
    
    func tapOnContinue(purchaseCompletion: @escaping () -> Void) async {
        if currentPage < maxPages - 1 {
            currentPage += 1
        } else {
            await viewModel.makePurchase(completion: purchaseCompletion)
        }
    }
}

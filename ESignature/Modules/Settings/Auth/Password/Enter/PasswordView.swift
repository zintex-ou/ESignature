
import SwiftUI
import LocalAuthentication

struct PasswordView: View {
    
    @StateObject var viewModel: PasswordViewModel
    
    private let isPad = UIDevice.current.userInterfaceIdiom == .pad
    
    @State private var passcode: String = ""
    
    private let pinLength: Int = 4
    
    @State private var shakeTrigger: CGFloat = 0
            
    var body: some View {
        ZStack {
            
            if !viewModel.isPresent {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.c191919)
                            .frame(width: 24, height: 24)
                            .onTapGesture {
                                viewModel.pop()
                            }
                     
                        Spacer()
                    }
                    
                    Spacer()
                }
                .padding(.top, 12)
                .padding(.horizontal, 16)
            }
            
            VStack(spacing: 32) {
                Spacer()
                Text(R.string.localizable.enterPassword())
                    .font(.headline)
                
                HStack(spacing: 24) {
                    ForEach(0..<pinLength, id: \.self) { index in
                        Circle()
                            .fill(index < passcode.count ? Color.black : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                    }
                }
                .modifier(ShakeEffect(animatableData: shakeTrigger))
                
                numbers
                
                Spacer()
                
                Button(action: {
                    viewModel.shouldShowingDialog = true
                }) {
                    Text(R.string.localizable.forgotAPassword())
                        .foregroundColor(.c7C7C7C)
                        .font(.custom(R.font.outfitRegular, size: 16))
                        .underline()
                }
                .padding(.bottom, 32)
                .confirmationDialog(
                    R.string.localizable.reset_password_warning(),
                    isPresented: $viewModel.shouldShowingDialog,
                    titleVisibility: .visible
                ) {
                    Button(R.string.localizable.resetPasscode()) {
                        viewModel.forgotPasswordReset()
                    }
        
                    Button(R.string.localizable.cancel(), role: .cancel) {
        
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .onChange(of: passcode) { newValue in
                if newValue.count == pinLength {
                    if viewModel.checkPassword(newValue) {
                        
                        if viewModel.isPresent {
                            viewModel.dismiss()
                            viewModel.onUnlockComplete?()
                        } else {
                            viewModel.showResetPassoword()
                        }
                    } else {
                        withAnimation(.default) {
                            shakeTrigger += 1
                        }
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        passcode = ""
                    }
                }
            }
        }
        .background(.cF7F7F7)
    }
    
    private func handleDigitTap(_ digit: String) {
        guard passcode.count < pinLength else { return }
        passcode.append(digit)
    }
    
    
    @ViewBuilder
    private var numbers: some View {
        VStack(spacing: isPad ? 54 : 24) {
            ForEach([["1","2","3"], ["4","5","6"], ["7","8","9"]], id: \.self) { row in
                HStack(spacing: isPad ? 54 : 24) {
                    ForEach(row, id: \.self) { digit in
                        NumberButton(title: digit) {
                            handleDigitTap(digit)
                        }
                    }
                }
            }
            
       
            HStack(spacing: isPad ? 54 : 24) {
                Group {
                    if viewModel.bioEnable && viewModel.isPresent {
                        
                        Button {
                            viewModel.authenticateWithBiometrics()
                        } label: {
                            Image(uiImage: getBiometricsName())
                                .frame(width: 74, height: 74)
                        }
                    } else {
                        Color.clear
                            .frame(width: 74, height: 74)
                    }
                }
                
                NumberButton(title: "0") {
                    handleDigitTap("0")
                }
                
                Color.clear
                    .frame(width: 74, height: 74)
            }
        }
    }
    
    func getBiometricsType() -> LABiometryType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        return context.biometryType
    }
    
    func getBiometricsName() -> UIImage {
        switch getBiometricsType() {
        case .faceID:
            return R.image.faceIDIcon() ?? UIImage()
        case .touchID:
            return R.image.touchIdIcon() ?? UIImage()
        case .none:
            return UIImage()
        @unknown default:
            return UIImage()
        }
    }
}

struct ShakeEffect: GeometryEffect {
    var travelDistance: CGFloat = 10
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = travelDistance * sin(animatableData * .pi * shakesPerUnit)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

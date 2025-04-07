
import SwiftUI

struct ResetPasswordView: View {
    
    @StateObject var viewModel: ResetPasswordViewModel
    
    private let isPad = UIDevice.current.userInterfaceIdiom == .pad
    
    @State private var passcode: String = ""
    
    private let pinLength: Int = 4
    
    var body: some View {
        ZStack {
            
            VStack() {
                HStack {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.c191919)
                        .frame(width: 24, height: 24)
                        .onTapGesture {
                            viewModel.popToRoot()
                        }
                 
                    Spacer()
                }
                
                Spacer()
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)
            
            VStack(spacing: 32) {
                Spacer()
                Text(R.string.localizable.enterNewPassword())
                    .font(.headline)
                
                HStack(spacing: 24) {
                    ForEach(0..<pinLength, id: \.self) { index in
                        Circle()
                            .fill(index < passcode.count ? Color.black : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                    }
                }
                
                numbers
                
                Spacer()
                
            }
            .frame(maxWidth: .infinity)
            .onChange(of: passcode) { newValue in
                if newValue.count == pinLength {
                    print(": \(newValue)")
                    viewModel.setPassword(newValue)
                    viewModel.popToRoot()
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
                NumberButton(title: "0") {
                    handleDigitTap("0")
                }
            }
        }
    }
}

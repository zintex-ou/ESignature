
import SwiftUI

struct AuthCellView: View {
    
    @ObservedObject var viewModel: AuthViewModel
    
    let title: String
    let timeInfo: Int
    let toggleable: Bool
    let hasInfo: Bool
    
    private let options: [Int] = [1, 5, 10, 20, 60]

    var body: some View {
        HStack(spacing: 0) {
            Text(title)
                .font(.custom(R.font.onestLight, size: 16))
            
            Spacer()
            
            if toggleable {
                Toggle("", isOn: bindingForSetting())
                    .toggleStyle(SwitchToggleStyle(tint: .c0666EB))
                    .allowsHitTesting(false)
            } else {
                if hasInfo {
                    Picker("", selection: $viewModel.seconds) {
                              ForEach(options, id: \.self) { value in
                                  Text("\(value)s")
                                      .tag(value)
                              }
                          }
                          .pickerStyle(.menu)
                          .tint(.c7C7C7C)
                }
                Image(systemName: "chevron.right")
                    .foregroundStyle(.c7C7C7C)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func bindingForSetting() -> Binding<Bool> {
        
        switch title {
        case R.string.localizable.enablePINCode():
            return $viewModel.pinEnable
        case R.string.localizable.biometricAuth():
            return $viewModel.bioEnable
        default:
            return .constant(false)
        }
    }
}



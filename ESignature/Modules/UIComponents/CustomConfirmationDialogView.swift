
import SwiftUI

struct CustomConfirmationDialogView: View {
    let title: String
    let message: String
    let primaryButtonTitle: String
    let secondaryButtonTitle: String
    @Binding var isPresented: Bool
    let primaryAction: () -> Void
    let secondaryAction: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 0) {
                Text(message)
                    .font(.system(size: 17))
                    .padding(.top, 24)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                
                Button(action: {
                    primaryAction()
                    isPresented = false
                }) {
                    Text(primaryButtonTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 24)
                
                Button(action: {
                    isPresented = false
                }) {
                    Text(secondaryButtonTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
        }
    }
}



import SwiftUI

struct RenameSheetView: View {
    @ObservedObject var viewModel: MainViewModel
    
    @Binding var shouldRenameSheet: Bool

    @State private var newName: String = ""
    let id: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(R.string.localizable.rename())
                .foregroundStyle(.c191919)
                .font(.custom(R.font.outfitSemiBold, size: 20))
            
            TextField(R.string.localizable.fileName(), text: $newName)
                         .font(.custom(R.font.outfitRegular, size: 16))
                         .padding(.horizontal, 12)
                         .frame(height: 48)
                         .background(.cF7F7F7)
                         .overlay(
                             RoundedRectangle(cornerRadius: 24)
                                .stroke(Color(.c7C7C7C), lineWidth: 0.5)
                         )
                         .cornerRadius(8)
                         .disableAutocorrection(true)
                         .textInputAutocapitalization(.never)
            
            Button {
                viewModel.renameDocument(documentID: id, newName: newName)
                viewModel.fetchDocuments()
                shouldRenameSheet = false
                
            } label: {
                Text(R.string.localizable.apply())
                    .font(.custom(R.font.outfitSemiBold, size: 16))
            }
            .buttonStyle(BlueButtonStyle())
            
            Spacer()
        }
        .background(.cF7F7F7)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}


import SwiftUI
import PrintingKit

struct SignedViewCell: View {
    
    let name: String?
    let image: Data?
    let isSigned: Bool
    let date: Date?
    let id: String?
    let path: String?
    
    @ObservedObject var viewModel: MainViewModel
    
    @State private var isShareSheetPresented = false
    @State private var sharedPDFData: Data?
    
    private enum Constants {
        static var signedText = R.string.localizable.signed
        static var unsignedText = R.string.localizable.unsigned
    }
    
    var body: some View {
        HStack {
            Image(uiImage: UIImage(data: image ?? Data()) ?? UIImage())
                .resizable()
                .scaledToFill()
                .clipped()
                .frame(width: 46, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .border(.cF7F7F7, width: 0.5)
            
            VStack(alignment: .leading) {
                Text(name ?? "")
                    .font(.custom(R.font.outfitSemiBold, size: 16))
                    .foregroundStyle(.c191919)
                
                HStack() {
                    
                    Text(localizedFormattedDate(from: date ?? Date()))
                        .font(.custom(R.font.outfitRegular, size: 14))
                        .foregroundStyle(.c7C7C7C)
                    
                    Text("·")
                        .font(.custom(R.font.outfitBold, size: 24))
                        .foregroundStyle(.c7C7C7C)
                    
                    Text(isSigned ? Constants.signedText : Constants.unsignedText)
                        .font(.custom(R.font.outfitRegular, size: 14))
                        .foregroundStyle(isSigned ? .c0F863F : .c7C7C7C)
                }
            }
            
            Spacer()
            
            Menu {
                Button(action: {
                    renameAction()
                }) {
                    Label(R.string.localizable.rename(), image: "renameIcon")
                    
                }
                
                Button(action: {
                    shareAction()
                }) {
                    Label(R.string.localizable.share(), image: "shareIcon")
                }
                
                Button(action: {
                    printAction()
                    }) {
                        Label(R.string.localizable.print(), image: "printIcon")
                    }
                
                
                Button(role: .destructive, action: {
                    deleteAction()
                }) {
                    Label(R.string.localizable.delete(), image: "deleteIcon")
                }
            } label: {
                Image(.more)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .padding(.trailing, 8)
            }
            
        }
        .frame(height: 46)
        .sheet(isPresented: $isShareSheetPresented) {
            if let pdfData = sharedPDFData {
                ShareSheet(activityItems: [pdfData])
            } else {
                Text("Cant load PDF")
            }
        }
    }
    
    private func renameAction() {
         viewModel.shouldRenameSheet = true
         viewModel.selectedDocumentID = id
     }
     
    private func shareAction() {
        guard let path = path else {
            print("Not true file path")
            return
        }
        let absURL = FileManagerService.shared.getAbsoluteURL(from: path)

        UIApplication.shared.shareFile(file: absURL)
    }


     private func printAction() {
         guard let path = path, let fileURL = URL(string: path) else {
             print("Invalid file path")
             return
         }
         do {
             try Printer.shared.print(.pdfFile(at: fileURL))
         } catch {
             print("Can't print file: \(fileURL), error: \(error.localizedDescription)")
         }
     }
     
     private func deleteAction() {
         viewModel.deleteDocument(docName: name ?? "")
         viewModel.fetchDocuments()
     }
    
    func localizedFormattedDate(from date: Date, locale: Locale = Locale.current) -> String {
        let languageCode = locale.languageCode ?? "en"
        
        let monthFormatter = DateFormatter()
        monthFormatter.locale = locale
        monthFormatter.dateFormat = "MMM"
        let month = monthFormatter.string(from: date)
        
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        
        let suffix: String = {
            switch languageCode {
            case "en":
                if (11...13).contains(day) {
                    return "th"
                }
                switch day % 10 {
                case 1: return "st"
                case 2: return "nd"
                case 3: return "rd"
                default: return "th"
                }
            case "pt", "es":
                return "º"
            case "de":
                return "."
            case "fr":
                return "e"
            case "it":
                return "°"
            default:
                return ""
            }
        }()
        
        let yearFormatter = DateFormatter()
        yearFormatter.locale = locale
        yearFormatter.dateFormat = "yyyy"
        let year = yearFormatter.string(from: date)
        
        return "\(month) \(day)\(suffix), \(year)"
    }
}

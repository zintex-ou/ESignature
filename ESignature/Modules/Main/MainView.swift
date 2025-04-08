
import SwiftUI
import RswiftResources
import ManySheets
import Combine
import PDFKit
import _PhotosUI_SwiftUI

struct MainView: View {
    
    @StateObject var viewModel: MainViewModel
    
    private let isPad = UIDevice.current.userInterfaceIdiom == .pad
    
    @State private var keyboardHeight: CGFloat = 0
     
     private var isKeyboardOpen: Bool {
         keyboardHeight > 0
     }
    
    let bottomSheetStyle = DefaultBottomSheetStyle(backgroundColor: .cF7F7F7, cornerRadius: 16)
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                navBar
                    .padding(.top, isPad ? 24 : 0)
                
                signedCountStack
                    .padding(.top, isPad ? 78 : 61)

                
                buttonsStack
                    .padding(.top, 54)
                
                            Spacer()
            }
            .zIndex(1)
            
            VStack(spacing: 0) {
                Image(R.image.mainBack)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .scaledToFill()
                    .frame(maxWidth: .infinity, minHeight: 406, maxHeight: 406)
                    .clipped()
                    .clipShape(RoundedBottomCorners(radius: 16))
                    .ignoresSafeArea()
                
                if viewModel.documents?.count == 0 {
                    Spacer()
                    emptyViewStack
                } else {
                        historyStack
//                        .padding(.top, 24)
                }
                
                Spacer()
            }

            
            DefaultBottomSheet(
                isOpen: $viewModel.shouldRenameSheet,
                style: bottomSheetStyle,
                options: [.enableHandleBar, .tapAwayToDismiss, .swipeToDismiss]
            ) {
                VStack(alignment: .leading, spacing: 0) {
                    RenameSheetView(
                        viewModel: viewModel,
                        shouldRenameSheet: $viewModel.shouldRenameSheet,
                        id: viewModel.selectedDocumentID ?? ""
                    )
                }
                .frame(height: isKeyboardOpen ? 245 + keyboardHeight : 245)
                .buttonStyle(PlainButtonStyle())
                .transaction { transaction in
                    transaction.animation = nil
                }
            }
            .zIndex(3)
            
            DefaultBottomSheet(
                isOpen: $viewModel.openAllDocs,
                style: bottomSheetStyle,
                options: [.enableHandleBar, .tapAwayToDismiss, .swipeToDismiss]
            ) {
                VStack(alignment: .leading, spacing: 0) {
                    AllDocsView(viewModel: viewModel)
                }
                .frame(height: UIScreen.main.bounds.height * 0.9)
                .buttonStyle(PlainButtonStyle())
                .transaction { transaction in
                    transaction.animation = nil
                }
            }
            .zIndex(2)
        }
        .background(.cF7F7F7)
        
        .onAppear {
            viewModel.fetchDocuments()
        }
        
        .onReceive(Publishers.keyboardHeight) { newHeight in
                 withAnimation(.easeOut(duration: 0.25)) {
                     self.keyboardHeight = newHeight
                 }
             }
        
        .sheet(item: $viewModel.activeSheet) { sheet in
            switch sheet {
            case .documentPicker:
                DocumentPicker(pdfDocument: $viewModel.pdfDocument, onSave: { pdf in
                    viewModel.savePDF(pdf)
                })
                
            default:
                emptyViewStack
            }
        }
        
        .photosPicker(isPresented: $viewModel.shouldAddImage,
                      selection: $viewModel.photoItem,
                      matching: .images,
                      photoLibrary: .shared())
        
        .onChange(of: viewModel.photoItem) { _ in
            Task {
                await viewModel.convertPhotoPickerItemToPDF(viewModel.photoItem ?? PhotosPickerItem(itemIdentifier: ""))
            }
        }
    }
    
    @ViewBuilder
    private var buttonsStack: some View {
        HStack(spacing: 0) {
            Button {
              if viewModel.checkTrialSubscription() {
                    viewModel.showScanner()
              } else {
                  viewModel.showPaywall()
              }
            } label: {
                VStack {
                    Image(R.image.scanImage)
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                    
                    Text(R.string.localizable.scan())
                        .foregroundStyle(.white)
                        .font(.custom(R.font.outfitSemiBold, size: 14))
                }
            }
            
            Spacer()
            
            Button {
                if viewModel.checkTrialSubscription() {
                    viewModel.addFile()
                } else {
                    viewModel.showPaywall()
                }
            } label: {
                VStack {
                    Image(R.image.addFileImage)
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                    
                    Text(R.string.localizable.addFile())
                        .foregroundStyle(.white)
                        .font(.custom(R.font.outfitSemiBold, size: 14))
                }
            }
            
            Spacer()
            
            Button {
                if viewModel.checkTrialSubscription() {
                    viewModel.addImage()
                } else {
                    viewModel.showPaywall()
                }
            } label: {
                VStack {
                    Image(R.image.addImageImage)
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                    
                    Text(R.string.localizable.addImage())
                        .foregroundStyle(.white)
                        .font(.custom(R.font.outfitSemiBold, size: 14))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Button {
                    viewModel.showSettings()
            } label: {
                VStack {
                    Image(R.image.settingsImage)
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                    
                    Text(R.string.localizable.settings())
                        .foregroundStyle(.white)
                        .font(.custom(R.font.outfitSemiBold, size: 14))
                }
            }
        }
        .frame(maxWidth: 321)
        .padding(.horizontal, 8)
    }
    
    @ViewBuilder
    private var navBar: some View {
        HStack {
            Text("E-signature")
                .foregroundStyle(.white)
                .font(.custom(R.font.outfitSemiBold, size: 24))
            
            Spacer()
            
            Button {
                    viewModel.showPaywall()
            } label: {
                Image(.pro)
                    .frame(width: 67, height: 28)
            }

        }
        .padding(.horizontal, 16)
        .padding(.top, 13)
    }
    
    @ViewBuilder
    private var signedCountStack: some View {
        VStack(spacing: 0) {
            Text("\(String(describing: viewModel.signedDocuments?.count ?? 0))")
                .foregroundStyle(.white)
                .frame(height: 64)
                .font(.custom(R.font.outfitSemiBold, size: 64))
            
            Text(R.string.localizable.signedDocument())
                .foregroundStyle(.white)
                .font(.custom(R.font.outfitRegular, size: 14))
            
        }
    }
    
    @ViewBuilder
    private var emptyViewStack: some View {
        VStack {
            Image(.empty)
                .resizable()
                .scaledToFit()
                .frame(width: 107, height: 116)
    
            Text(R.string.localizable.noSignedFilesYet())
                .font(.custom(R.font.outfitRegular, size: 16))
                .foregroundStyle(.black)
            
            Text(R.string.localizable.yourDocumentsWillAppearHere())
                .font(.custom(R.font.outfitRegular, size: 16))
                .foregroundStyle(.c7C7C7C)
        }
    }
    
    @ViewBuilder
    private var historyStack: some View {
        ZStack(alignment: .top) {
            VStack {
                HStack {
                    Text(R.string.localizable.recent())
                        .font(.custom(R.font.outfitRegular, size: 14))
                        .foregroundStyle(.c7C7C7C)
                    
                    Spacer()
                }
                .padding(.top, 16)
                ScrollView {
                VStack(spacing: 12) {
                 

                    ForEach(sortDisplayDocs(), id: \.id) { doc in
                        HStack {
                            SignedViewCell(name: doc.name,
                                           image: doc.preview,
                                           isSigned: doc.isSigned,
                                           date: doc.date,
                                           id: doc.id,
                                           path: doc.url, 
                                           viewModel: viewModel)
                            .onTapGesture {
                                viewModel.showFile(doc.url ?? "", fileName: doc.name)
                            }
                        }
                    }
                }
            }
                .scrollDisabled(true)
                
                Button {
                    viewModel.openAllDocs = true
                } label: {
                    Text(R.string.localizable.seeAll())
                        .font(.custom(R.font.outfitSemiBold, size: 16))
                        .padding(.vertical, 14)
                        .foregroundStyle(.c0666EB)
                }
              
            }
            .padding(.horizontal, 16)
        }
        .frame(minHeight: 178, maxHeight: 612)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, isPad ? 24 : 16)
    }
    
    private func sortDisplayDocs() -> [DocumentEntity] {
        let sortedDocuments = viewModel.documents?.sorted {
            ($0.date ?? Date()) > ($1.date ?? Date())
        } ?? []

        let displayedDocuments = Array(sortedDocuments.prefix(isPad ? 8 : 3))
        
        return displayedDocuments
    }
}

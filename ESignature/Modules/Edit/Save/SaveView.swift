
import SwiftUI
import PDFKit

struct SaveView: View {
    
    @ObservedObject var viewModel: EditViewModel
    
    @State private var pdfViewRef: PDFView?

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                navBar
                
                GeometryReader { geometry in
                    
                    ZStack {
                        VStack(spacing: 0) {
                            
                            if let _ = viewModel.fileURL {
                                
                                Spacer()
                                
                                Text(R.string.localizable.yourDocumentIsReady())
                                    .font(.custom(R.font.outfitSemiBold, size: 20))
                                    .foregroundStyle(.c191919)
                                
                                HStack {
                                    
                                    Spacer()
                                    
                                    PDFKitRepresentedView(viewModel: viewModel.pdfViewModel, onCreatePDFView: { pdfView in
                                        DispatchQueue.main.async {
                                            self.pdfViewRef = pdfView
                                        }
                                        
                                    })
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .aspectRatio(3/4, contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .padding(.horizontal, 16)
                                    .padding(.top, 16)
                                    
                                    Spacer()
                                }
                                
                                Spacer()
                                
                                if let pdfView = pdfViewRef {
                                    if viewModel.pdfViewModel.thumbnails.count > 1 {
                                        PreviewThumbnail(viewModel: viewModel.pdfViewModel, pdfViewProxy: pdfView)
                                            .frame(height: 68)
                                            .padding(.vertical, 24)
                                    } else {
                                        Color.clear
                                              .frame(height: 68)
                                              .padding(.vertical, 24)
                                    }
                                }
                            }
                        }
                    }
                }
                tabBar
            }
        }
        .background(Color(.cF7F7F7))
    }
        
        @ViewBuilder
        private var tabBar: some View {
            VStack {
                HStack(spacing: 0) {
               
                        Button {
                            viewModel.saveDocument()

                        } label: {
                            Text(R.string.localizable.share())
                                .font(.custom(R.font.outfitSemiBold, size: 16))
                        }
                        .buttonStyle(BlueButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        
        @ViewBuilder
        private var navBar: some View {
            ZStack {
                HStack(spacing: 8) {
                    Button {
                        viewModel.popToRoot()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                            .frame(width: 24, height: 24)
                    }
                    
                    Spacer()
                    
                    Button {
                        viewModel.printAction()
                    } label: {
                        Image(R.image.printIcon)
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
        }
    }

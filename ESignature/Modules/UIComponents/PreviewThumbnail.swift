
import SwiftUI
import PDFKit

    struct PreviewThumbnail: View {
        @ObservedObject var viewModel: PDFViewModel
        var pdfViewProxy: PDFView
        
        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(viewModel.thumbnails.indices, id: \.self) { i in
                        let thumbnail = viewModel.thumbnails[i]
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay {
                                if i == viewModel.currentPageIndex {
                                    RoundedRectangle(cornerRadius: 4)
                                        .inset(by: 0.5)
                                        .stroke(.blue, lineWidth: 1)
                                }
                            }
                            .onTapGesture {
                                viewModel.goToPage(i, in: pdfViewProxy)
                            }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

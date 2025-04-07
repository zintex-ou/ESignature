

import SwiftUI
import PDFKit

final class PDFViewModel: ObservableObject {
    @Published var thumbnails: [UIImage] = []
    @Published var currentPageIndex: Int = 0
    
    @Published var document: PDFDocument? {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    init(url: URL) {
        if let doc = PDFDocument(url: url) {
            self.document = doc
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.generateThumbnails(from: doc)
            }
        }
    }
    
    private func generateThumbnails(from doc: PDFDocument) {
        let pageCount = doc.pageCount
        for i in 0..<pageCount {
            if let page = doc.page(at: i) {
                let thumbnail = page.thumbnail(of: CGSize(width: 48, height: 68), for: .cropBox)
                DispatchQueue.main.async {
                    self.thumbnails.append(thumbnail)
                }
            }
        }
    }
    
    func goToPage(_ index: Int, in pdfView: PDFView) {
        guard let doc = document, let page = doc.page(at: index) else { return }
        pdfView.go(to: page)
        currentPageIndex = index
    }
}

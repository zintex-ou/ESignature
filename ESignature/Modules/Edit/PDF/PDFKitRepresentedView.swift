
import SwiftUI
import PDFKit

struct PDFKitRepresentedView: UIViewRepresentable {
    @ObservedObject var viewModel: PDFViewModel
    var onCreatePDFView: ((PDFView) -> Void)?
    
    let pdfView = PDFView()
    
    func makeUIView(context: Context) -> PDFView {
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        pdfView.usePageViewController(false, withViewOptions: nil)
        pdfView.backgroundColor = .white
        pdfView.pageShadowsEnabled = false
        
        if let document = viewModel.document {
            pdfView.document = document
            if let page = document.page(at: viewModel.currentPageIndex) {
                pdfView.go(to: page)
            }
        }
        
        pdfView.delegate = context.coordinator
        onCreatePDFView?(pdfView)
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        if let document = viewModel.document,
           let page = document.page(at: viewModel.currentPageIndex),
           uiView.currentPage != page {
            uiView.go(to: page)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PDFViewDelegate {
        var parent: PDFKitRepresentedView
        
        init(_ parent: PDFKitRepresentedView) {
            self.parent = parent
        }
        
        func pdfViewPageChanged(_ sender: PDFView) {
            if let currentPage = sender.currentPage,
               let doc = sender.document {
                let pageIndex = doc.index(for: currentPage)
                parent.viewModel.currentPageIndex = pageIndex
            }
        }
    }
}

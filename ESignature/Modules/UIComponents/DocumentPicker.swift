
import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var pdfDocument: PDFDocument?
    var onSave: (PDFDocument) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.image, UTType.pdf], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            let fileManager = FileManager.default
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let destinationURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)
            
            var didStartAccessing = false
            if url.startAccessingSecurityScopedResource() {
                didStartAccessing = true
            }
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            do {
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.copyItem(at: url, to: destinationURL)
                
                if url.pathExtension.lowercased() == "pdf" {
                    let pdfDocument = PDFDocument(url: destinationURL)
                    parent.pdfDocument = pdfDocument
                    if let pdfDocument = pdfDocument {
                        parent.onSave(pdfDocument)
                    }
                } else if let image = UIImage(contentsOfFile: destinationURL.path) {
                    let pdfDocument = PDFDocument()
                    if let pdfPage = PDFPage(image: image) {
                        pdfDocument.insert(pdfPage, at: 0)
                    }
                    parent.pdfDocument = pdfDocument
                    parent.onSave(pdfDocument)
                }
            } catch {
                print("Failed to import file in DocumentPicker: \(error.localizedDescription)")
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            controller.dismiss(animated: true)
        }
    }
}

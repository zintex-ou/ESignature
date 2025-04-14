import Foundation
import _PhotosUI_SwiftUI
import CoreData
import PDFKit
import SwiftUI
import UIKit
import UniformTypeIdentifiers

final class MainViewModel: NSObject, ObservableObject {
    weak var output: MainOutput?
    
    private var fileManagerService = FileManagerService.shared
    private var coreDataManager = CoreDataManager.shared
    private var keychainManager = KeychainManager()
    
    @Published var fileCreationDates: [URL: Date] = [:]
    @Published var savedPDFs: [URL] = []
    @Published var fileSizes: [URL: Int64] = [:]
    @Published var activeSheet: ActiveSheet?
    @Published var pdfDocument: PDFDocument?
    
    @Published var shouldRenameSheet: Bool = false
    @Published var shouldAddImage: Bool = false
    
    @Published var shouldDeleteAction: Bool = false
    
    @Published var openAllDocs: Bool = false
    
    @Published var documents: [DocumentEntity]?
    @Published var signedDocuments: [DocumentEntity]?
    @Published var selectedDocumentID: String?
    
    @Published var scannedImages: [UIImage] = []

    @Published var photoItem: PhotosPickerItem? = nil
    
    private let isPad = UIDevice.current.userInterfaceIdiom == .pad
        
    init(output: MainOutput?) {
        self.output = output
        super.init()
        self.loadSavedPDFs()
    }
    
    enum ActiveSheet: Identifiable {
        case addSheet, scanner, imagePicker, documentPicker
        
        var id: UUID {
            UUID()
        }
    }
    
    @MainActor
    func savePDF(_ pdfDocument: PDFDocument) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            let existingFiles = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            let documentNumbers = existingFiles.compactMap { url -> Int? in
                let filename = url.lastPathComponent
                let pattern = #"Document (\d+)\.pdf"#
                let regex = try? NSRegularExpression(pattern: pattern)
                if let match = regex?.firstMatch(in: filename, range: NSRange(location: 0, length: filename.utf16.count)),
                   let range = Range(match.range(at: 1), in: filename),
                   let number = Int(filename[range]) {
                    return number
                }
                return nil
            }
            
            let nextNumber = (documentNumbers.max() ?? 0) + 1
            let pdfURL = documentsDirectory.appendingPathComponent("Document \(nextNumber).pdf")
            
            pdfDocument.write(to: pdfURL)
            print("PDF saved as: \(pdfURL.lastPathComponent)")
            loadSavedPDFs()
            addFile(pdfURL.lastPathComponent, fileName: pdfURL.lastPathComponent)
        } catch {
            print("Failed to save PDF: \(error.localizedDescription)")
        }
    }
    
    func groupPDFsByDate(_ pdfs: [URL]) -> [Date: [URL]] {
        var groupedPDFs: [Date: [URL]] = [:]
        
        for pdf in pdfs {
            if let creationDate = fileCreationDates[pdf]?.startOfDay {
                groupedPDFs[creationDate, default: []].append(pdf)
            }
        }
        
        return groupedPDFs
    }
    
    func showScanner() {
        let binding = Binding<[UIImage]>(
            get: { self.scannedImages },
            set: { [weak self] images in
                self?.scannedImages = images
                if let self = self, !images.isEmpty {
                    Task { @MainActor in
                        await self.convertScannedImagesToPDF()
                    }
                }
            }
        )
        output?.showScanner(scanResult: binding)
    }

    @MainActor
    private func convertScannedImagesToPDF() async {
        guard !scannedImages.isEmpty else { return }
        
        let pdfDocument = PDFDocument()
        
        for (index, image) in scannedImages.enumerated() {
            if let pdfPage = PDFPage(image: image) {
                pdfDocument.insert(pdfPage, at: index)
            }
        }
        
        savePDF(pdfDocument)
        scannedImages.removeAll()
    }
    
    func showSettings() {
        output?.showSettings()
    }
    
    func showPaywall() {
        if isPad {
            output?.showPadPaywall()
        } else {
            output?.showPaywall()
        }
    }
    
    func loadSavedPDFs() {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey])
            let pdfFiles = fileURLs.filter { $0.pathExtension.lowercased() == "pdf" }
            
            savedPDFs = pdfFiles
            fileSizes = [:]
            fileCreationDates = [:]
            
            for file in pdfFiles {
                if let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    fileSizes[file] = Int64(fileSize)
                }
                if let creationDate = try? file.resourceValues(forKeys: [.creationDateKey]).creationDate {
                    fileCreationDates[file] = creationDate
                }
            }
        } catch {
            print("Failed to load files: \(error.localizedDescription)")
        }
    }
    
    func generateThumbnail(for url: URL) -> UIImage? {
        guard let document = PDFDocument(url: url),
              let page = document.page(at: 0) else {
            return nil
        }
        
        let thumbnailSize = CGSize(width: 50, height: 50)
        return page.thumbnail(of: thumbnailSize, for: .mediaBox)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    func addFile() {
        activeSheet = .documentPicker
    }
    
    func addImage() {
        shouldAddImage = true
    }
    
    @MainActor
    func addFile(_ relativePath: String, fileName: String?) {
        let fileURL = fileManagerService.getAbsoluteURL(from: relativePath)
        output?.showEdit(image: nil, fileURL: fileURL, fileName: fileName, isHistory: false, documentID: selectedDocumentID ?? "")
    }
    
    @MainActor
    func showFile(_ relativePath: String, fileName: String?) {
        let fileURL = fileManagerService.getAbsoluteURL(from: relativePath)
        output?.showEdit(image: nil, fileURL: fileURL, fileName: fileName, isHistory: true, documentID: selectedDocumentID ?? "")
    }
    
    func fetchDocuments() {
        documents = coreDataManager.fetchDocuments()
        signedDocuments = documents?.filter { $0.isSigned == true}
    }
    
    func deleteDocument(docName: String) {
        fileManagerService.deleteFile(fileName: docName)
        
        let fetchRequest: NSFetchRequest<DocumentEntity> = DocumentEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", docName)
        
        do {
            let results = try coreDataManager.context.fetch(fetchRequest)
            for documentEntity in results {
                coreDataManager.context.delete(documentEntity)
            }
            coreDataManager.saveContext()
            print("Document with name \(docName) has been deleted.")
        } catch {
            print("Failed to delete document from Core Data: \(error.localizedDescription)")
        }
    }
    
    func renameDocument(documentID: String, newName: String) {
        
        guard let documentEntity = coreDataManager.loadDocumentItem(with: documentID) else {
            print("Document with ID \(documentID) not found in Core Data")
            return
        }
        
        guard let docURLString = documentEntity.url else {
            print("Document URL is missing")
            return
        }
        let oldAbsoluteURL = fileManagerService.getAbsoluteURL(from: docURLString)
        
        do {
            let newAbsoluteURL = try fileManagerService.renameFile(from: oldAbsoluteURL, to: newName)
            
            documentEntity.name = newName
            documentEntity.url = fileManagerService.getRelativePath(for: newAbsoluteURL)
            documentEntity.date = Date()
            
            coreDataManager.saveContext()
            print("Document renamed to \(newName)")
        } catch {
            print("Failed to rename document: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func convertPhotoPickerItemToPDF(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                print("Cant load image")
                return
            }
            
            let pdfDocument = image.toPDFDocument()
            
            savePDF(pdfDocument)
            loadSavedPDFs()
            
            print("PDF sucsess sreated")
            
        } catch {
            print("Consert error: \(error.localizedDescription)")
        }
    }
    
    func checkPremium() -> Bool {
        return PurchaseManager.shared.isPremium
    }
    
    func checkTrialSubscription() -> Bool {
#if DEBUG
        return true
#else
    if !PurchaseManager.shared.isPremium {
            if keychainManager.hasUsedFreeAccess == true {
                return false
                
            } else {
                keychainManager.hasUsedFreeAccess = true
                return true
            }
        } else {
            return true
        }
#endif
    }
}

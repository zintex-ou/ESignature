import Foundation
import SwiftUI
import PDFKit
import PhotosUI
import UIKit
import CoreData
import BackgroundRemoval

final class EditViewModel: ObservableObject {
    @Published var selectedOverlay: OverlaysModel? = nil
    @Published var selectedStampIndex: Int? = nil
    @Published var twirlCircleRadius: Float = 50.0
    @Published var shouldShowTextEditor = false
    
    @Published var shouldShowStampSheet: Bool = false
    @Published var shouldShowSignSheet: Bool = false
    @Published var shouldShowWatermarkSheet: Bool = false
    
    
    @Published var shouldShowGalleryStamp: Bool = false
    @Published var shouldShowFileStamp: Bool = false
    @Published var shouldShowGallerySign: Bool = false
    @Published var shouldShowFileSign: Bool = false
    @Published var shouldShowGalleryWatermark: Bool = false
    @Published var shouldShowFileWatermark: Bool = false
    
    @Published var shouldShowingDialog: Bool = false
    @Published var showSuccessfullySavesView: Bool = false
    @Published var fileURL: URL?
    @Published var image: UIImage?
    @Published var editState: Bool = false
    @Published var editImage: UIImage?
    @Published var imageName: String?
    @Published var fileName: String?
    @Published var isSaved: Bool = false
    
    // MARK: DrawView
    @Published var drawingColor: Color = .black
    @State var showColorPicker = false
    @Published var lines: [Line] = []
    @Published var lineWidth: Double = 1.0
    @Published var imageSize: CGSize = CGSize(width: 0, height: 0)
    private var undoStack: [EditingState] = []
    private var redoStack: [EditingState] = []
    @Published var shareURL: URL?
    @Published var showShareSheet: Bool = false
        
    var pdfDocument: PDFDocument?
    
    @ObservedObject var pdfViewModel: PDFViewModel
    
    var onStampAdded: ((UIImage, CGRect) -> Void)?
    var onSignAdded: ((UIImage, CGRect) -> Void)?
    var onWatermarkAdded: ((UIImage, CGRect) -> Void)?
    
    let isHistory: Bool
    var documentID: String?
    
    private var coreDataManager = CoreDataManager.shared
    private var fileManagerService = FileManagerService.shared
    private var task: Task<Void, Never>?
    
    @Published var stampsModel: [OverlaysModel] = []
    @Published var signsModel: [OverlaysModel] = []
    @Published var watermarksModel: [OverlaysModel] = []
    
    @Published var stampItem: PhotosPickerItem? = nil
    @Published var signItem: PhotosPickerItem? = nil
    @Published var watermarkItem: PhotosPickerItem? = nil
    
    weak var output: EditOutput?
    
    func showDraw() {
        output?.showDraw(self)
    }
    
    lazy var signCompletion: (UIImage) -> Void = { [weak self] image in
        DispatchQueue.main.async {
            self?.editImage = image
            self?.editState = true
        }
    }
    
    init(output: EditOutput?, image: UIImage? = nil, imageName: String? = nil, fileURL: URL? = nil, fileName: String? = nil, isHistory: Bool, documentID: String? = nil) {
        self.image = image?.fixedOrientation()
        self.fileURL = fileURL
        self.output = output
        self.isHistory = isHistory
        self.imageName = imageName
        self.fileName = fileName
        self.documentID = documentID
        self.pdfViewModel = PDFViewModel(url: fileURL ?? URL(string: "about:blank")!)
        self.pdfDocument = pdfViewModel.document
        
        if !isHistory {
            saveObject()
        }
    }
    
    func fetchStamps() {
        let stamps = coreDataManager.fetchStamps()
        print("Fetched \(stamps.count) stamps from Core Data")
        
        stampsModel = stamps.compactMap { stamp -> OverlaysModel? in
            guard let idString = stamp.id,
                  let name = stamp.name,
                  let id = UUID(uuidString: idString),
                  let image = fileManagerService.getImage(fileName: name) else { return nil }
            
            return OverlaysModel(id: id, name: name, image: image, type: .stamp)
        }
        
        print("Converted to \(stampsModel.count) valid overlay models")
    }
    
    func fetchSigns() {
        let signs = coreDataManager.fetchSigns()
        print("Fetched \(signs.count) stamps from Core Data")
        
        signsModel = signs.compactMap { sign -> OverlaysModel? in
            guard let idString = sign.id,
                  let name = sign.name,
                  let id = UUID(uuidString: idString),
                  let image = fileManagerService.getImage(fileName: name) else { return nil }
            print("Converted to \(String(describing: sign.url)) valid overlay models")
            
            
            return OverlaysModel(id: id, name: name, image: image, type: .signature)
        }
        
        print("Converted to \(signsModel.count) valid overlay models")
    }
    
    func fetchWatermarks() {
        let watermarks = coreDataManager.fetchWatermark()
        print("Fetched \(watermarks.count) stamps from Core Data")
        
        watermarksModel = watermarks.compactMap { watermarks -> OverlaysModel? in
            guard let idString = watermarks.id,
                  let name = watermarks.name,
                  let id = UUID(uuidString: idString),
                  let image = fileManagerService.getImage(fileName: name) else { return nil }
            print("Converted to \(String(describing: watermarks.url)) valid overlay models")
            
            
            return OverlaysModel(id: id, name: name, image: image, type: .watermark)
        }
        
        print("Converted to \(signsModel.count) valid overlay models")
    }
    
    func saveDocument() {
        guard let pdfDoc = pdfViewModel.document, let pdfData = pdfDoc.dataRepresentation() else {
            print("No pdf file")
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [pdfData], applicationActivities: nil)
        
        DispatchQueue.main.async {
            if let topVC = UIApplication.shared.windows.first?.rootViewController {
                topVC.present(activityViewController, animated: true, completion: nil)
            }
        }
    }
    
    func saveObject() {
        task = Task(priority: .high) { [weak self] in
            guard let self = self else { return }
            if let image = self.image {
                guard let pdfData = image.toPDFData() else { return }
                let uniqueFileURL = self.fileManagerService.createUniqueFileURL(extension: "pdf")
                do {
                    try self.fileManagerService.saveFile(data: pdfData, to: uniqueFileURL)
                    let relativePath = self.fileManagerService.getRelativePath(for: uniqueFileURL)
                    let documentID = UUID().uuidString
                    self.documentID = documentID
                    let existingDocuments = coreDataManager.fetchDocuments()
                    let newDocumentNumber = existingDocuments.count + 1
                    let documentName = "Document \(newDocumentNumber)"
                    let previewImage = image.fixedOrientation()
                    self.coreDataManager.createDocument(
                        id: documentID,
                        isSigned: false,
                        url: relativePath,
                        name: documentName,
                        image: previewImage
                    )
                } catch {
                    print("Failed to save image as PDF: \(error.localizedDescription)")
                }
            } else if let sourceURL = self.fileURL {
                let fileName = self.fileName ?? sourceURL.lastPathComponent
                let destinationURL = self.fileManagerService.createUniqueFileURL(extension: sourceURL.pathExtension)
                do {
                    try self.fileManagerService.copyFile(from: sourceURL, to: destinationURL)
                    let relativePath = self.fileManagerService.getRelativePath(for: destinationURL)
                    let documentID = UUID().uuidString
                    self.documentID = documentID
                    
                    var previewImage = UIImage()
                    
                    if let pdfDocument = PDFDocument(url: destinationURL),
                       let firstPage = pdfDocument.page(at: 0) {
                        let pageRect = firstPage.bounds(for: .mediaBox)
                        let scale: CGFloat = 0.5
                        let targetSize = CGSize(
                            width: pageRect.width * scale,
                            height: pageRect.height * scale
                        )
                        previewImage = firstPage.thumbnail(of: targetSize, for: .mediaBox)
                    } else if let image = UIImage(contentsOfFile: destinationURL.path) {
                        previewImage = image
                    }
                    self.coreDataManager.createDocument(
                        id: documentID,
                        isSigned: false,
                        url: relativePath,
                        name: (fileName as NSString).deletingPathExtension,
                        image: previewImage
                    )
                    self.fileURL = destinationURL
                } catch {
                    print("Failed to copy file: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func saveSigned(id: String) {
        task = Task(priority: .high) { [weak self] in
            guard let self = self else { return }
            
            if let pdfDoc = self.pdfViewModel.document, let fileURL = self.fileURL {
                if pdfDoc.write(to: fileURL) {
                    print("PDF with overlays saved.")
                } else {
                    print("Cant save pdf with overlays.")
                }
                
                if let firstPage = pdfDoc.page(at: 0) {
                    let pageRect = firstPage.bounds(for: .mediaBox)
                    let scale: CGFloat = 0.5
                    let targetSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
                    let thumbnailImage = firstPage.thumbnail(of: targetSize, for: .mediaBox)
                    let previewData = thumbnailImage.fixedOrientation().jpegData(compressionQuality: 0.5) ?? Data()
                    
                    self.coreDataManager.updatePreviewOfDocument(with: id, isSigned: true, preview: previewData)
                }
            } else if let image = self.image {
                let previewData = image.fixedOrientation().jpegData(compressionQuality: 0.5) ?? Data()
                self.coreDataManager.updatePreviewOfDocument(with: id, isSigned: true, preview: previewData)
            }
        }
    }
    
    func pop() {
        output?.pop()
    }
    
    func tapOnPreviewImage(stmp: OverlaysModel) {
        selectedOverlay = stmp
    }
    
    func tapOnSign() {
        shouldShowSignSheet = true
        
    }
    
    func tapOnStamp() {
        shouldShowStampSheet = true
    }
    
    func tapOnWatermark() {
        shouldShowWatermarkSheet = true
    }
    
    func showTextEditor() {
        shouldShowTextEditor = true
    }
    
//    func showTextEditView() {
//        output?.showTextEdit(self)
//    }
    
    func showGalleryStamp() {
        shouldShowGalleryStamp = true
    }
    
    func showFileStamp() {
        shouldShowFileStamp = true
    }
    
    func showGallerySign() {
        shouldShowGallerySign = true
    }
    
    func showFileSign() {
        shouldShowFileSign = true
    }
    
    func showGalleryWatermark() {
        shouldShowGalleryWatermark = true
    }
    
    func showFileWatermark() {
        shouldShowFileWatermark = true
    }
    
    func showDialog() {
        shouldShowingDialog = true
    }
    
    func shouldShowSuccessfullySavesView(_ bool: Bool) {
        showSuccessfullySavesView = bool
    }
    
    func loadStampFromPhotos() {
        guard let stampItem else { return }
        
        Task {
            do {
                if let data = try await stampItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    let processedImage = try BackgroundRemoval().removeBackground(image: uiImage)
                    
                    
                    let annotationFrame = CGRect(x: 100, y: 100, width: 150, height: 150)
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.onStampAdded?(processedImage, annotationFrame)
                    }
                    
                    let existingStamps = coreDataManager.fetchStamps()
                    let newStampNumber = existingStamps.count + 1
                    let stampName = "Stamp \(newStampNumber)"
                    guard let imageUrl = FileManagerService.shared.saveImage(image: processedImage, fileName: stampName) else {
                        print("Failed to save image")
                        return
                    }
                    
                    coreDataManager.createStamp(id: UUID().uuidString, url: imageUrl.path, name: stampName)
                    print("createStamp \(imageUrl) with name: \(stampName)")
                    
                    await MainActor.run { [weak self] in
                        self?.fetchStamps()
                        NotificationCenter.default.post(name: Notification.loadedStamp, object: nil)
                        self?.shouldShowSuccessfullySavesView(true)
                    }
                }
            } catch {
                print("Failed to load image:", error)
            }
        }
    }
    
    func loadStamp(uiImage: UIImage) {
        Task {
            do {
                let processedImage = try BackgroundRemoval().removeBackground(image: uiImage)
                
                
                let annotationFrame = CGRect(x: 100, y: 100, width: 150, height: 150)
                
                DispatchQueue.main.async { [weak self] in
                    self?.onStampAdded?(processedImage, annotationFrame)
                }
                
                let existingStamps = coreDataManager.fetchStamps()
                let newStampNumber = existingStamps.count + 1
                let stampName = "Stamp \(newStampNumber)"
                guard let imageUrl = FileManagerService.shared.saveImage(image: processedImage, fileName: stampName) else {
                    print("Failed to save image")
                    return
                }
                
                coreDataManager.createStamp(id: UUID().uuidString, url: imageUrl.path, name: stampName)
                print("createStamp \(imageUrl) with name: \(stampName)")
                
                await MainActor.run { [weak self] in
                    self?.fetchStamps()
                    NotificationCenter.default.post(name: Notification.loadedStamp, object: nil)
                    self?.shouldShowSuccessfullySavesView(true)
                }
                
            } catch {
                print("Failed to load image:", error)
            }
        }
    }
    
    func loadSignFromPhotos() {
        print("loadSignFromPhotos")
        guard let signItem else { return }
        
        Task {
            do {
                if let data = try await signItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    let processedImage = try BackgroundRemoval().removeBackground(image: uiImage)
                    
                    
                    let annotationFrame = CGRect(x: 100, y: 100, width: 150, height: 150)
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.onSignAdded?(processedImage, annotationFrame)
                    }
                    
                    let existingSigns = coreDataManager.fetchSigns()
                    let newSignNumber = existingSigns.count + 1
                    let signName = "Sign \(newSignNumber)"
                    guard let imageUrl = FileManagerService.shared.saveImage(image: processedImage, fileName: signName) else {
                        print("Failed to save image")
                        return
                    }
                    
                    coreDataManager.createSign(id: UUID().uuidString, url: imageUrl.path, name: signName)
                    print("createSign \(imageUrl) with name: \(signName)")
                    
                    await MainActor.run { [weak self] in
                        self?.fetchSigns()
                        NotificationCenter.default.post(name: Notification.loadedStamp, object: nil)
                        self?.shouldShowSuccessfullySavesView(true)
                    }
                }
            } catch {
                print("Failed to load image:", error)
            }
        }
    }
    
    func loadSign(uiImage: UIImage, removeBack: Bool) {
        Task {
            do {
                let processedImage = uiImage
                
                if removeBack {
                    let processedImage = try BackgroundRemoval().removeBackground(image: uiImage)
                }
                
                let annotationFrame = CGRect(x: 100, y: 100, width: 150, height: 150)
                
                DispatchQueue.main.async { [weak self] in
                    self?.onSignAdded?(processedImage, annotationFrame)
                }
                
                let existingSigns = coreDataManager.fetchSigns()
                let newSignsNumber = existingSigns.count + 1
                let signName = "Sign \(newSignsNumber)"
                guard let imageUrl = FileManagerService.shared.saveImage(image: processedImage, fileName: signName) else {
                    print("Failed to save image")
                    return
                }
                
                coreDataManager.createSign(id: UUID().uuidString, url: imageUrl.path, name: signName)
                print("createSign \(imageUrl) with name: \(signName)")
                
                await MainActor.run { [weak self] in
                    self?.fetchSigns()
                    NotificationCenter.default.post(name: Notification.loadedStamp, object: nil)
                    self?.shouldShowSuccessfullySavesView(true)
                }
                
            } catch {
                print("Failed to load image:", error)
            }
            
        }
    }
    
    func loadWatermarkFromPhotos() {
        print("loadWatermarkFromPhotos")
        guard let watermarkItem else { return }
        
        Task {
            do {
                if let data = try await watermarkItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    let processedImage = try BackgroundRemoval().removeBackground(image: uiImage)
                    
                    
                    let annotationFrame = CGRect(x: 100, y: 100, width: 150, height: 150)
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.onWatermarkAdded?(processedImage, annotationFrame)
                    }
                    
                    let existingWatermark = coreDataManager.fetchWatermark()
                    let newWatermarkNumber = existingWatermark.count + 1
                    let watermarkName = "Watermark \(newWatermarkNumber)"
                    guard let imageUrl = FileManagerService.shared.saveImage(image: processedImage, fileName: watermarkName) else {
                        print("Failed to save image")
                        return
                    }
                    
                    coreDataManager.createWatermark(id: UUID().uuidString, url: imageUrl.path, name: watermarkName)
                    print("createWatermark \(imageUrl) with name: \(watermarkName)")
                    
                    await MainActor.run { [weak self] in
                        self?.fetchWatermarks()
                        NotificationCenter.default.post(name: Notification.loadedWatermark, object: nil)
                        self?.shouldShowSuccessfullySavesView(true)
                    }
                }
            } catch {
                print("Failed to load image:", error)
            }
        }
    }
    
    func loadWatermark(uiImage: UIImage) {
        Task {
            do {
                let processedImage = try BackgroundRemoval().removeBackground(image: uiImage)
                
                let annotationFrame = CGRect(x: 100, y: 100, width: 150, height: 150)
                
                DispatchQueue.main.async { [weak self] in
                    self?.onWatermarkAdded?(processedImage, annotationFrame)
                }
                
                let existingWatermark = coreDataManager.fetchWatermark()
                let newWatermarkNumber = existingWatermark.count + 1
                let watermarkName = "Watermark \(newWatermarkNumber)"
                guard let imageUrl = FileManagerService.shared.saveImage(image: processedImage, fileName: watermarkName) else {
                    print("Failed to save image")
                    return
                }
                
                coreDataManager.createWatermark(id: UUID().uuidString, url: imageUrl.path, name: watermarkName)
                print("createWatermark \(imageUrl) with name: \(watermarkName)")
                
                await MainActor.run { [weak self] in
                    self?.fetchWatermarks()
                    NotificationCenter.default.post(name: Notification.loadedWatermark, object: nil)
                    self?.shouldShowSuccessfullySavesView(true)
                }
                
            } catch {
                print("Failed to load image:", error)
            }
        }
    }
    
    func pdfToImage(pdf: PDFDocument) -> UIImage? {
        guard let page = pdf.page(at: 0) else { return nil }
        
        let pageRect = page.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        
        return renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(CGRect(origin: .zero, size: pageRect.size))
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
    }
    
    // MARK: Draw methods
    
    func dissmis() {
        output?.dissmis()
    }
    
    func saveState() {
        let currentState = EditingState(
            lines: lines,
            lineWidth: lineWidth,
            imageSize: imageSize
        )
        undoStack.append(currentState)
        redoStack.removeAll()
    }
    
    func undo() {
        guard let lastState = undoStack.popLast() else { return }
        let currentState = EditingState(
            lines: lines,
            lineWidth: lineWidth,
            imageSize: imageSize
        )
        redoStack.append(currentState)
        apply(state: lastState)
    }
    
    func redo() {
        guard let lastState = redoStack.popLast() else { return }
        let currentState = EditingState(
            lines: lines,
            lineWidth: lineWidth,
            imageSize: imageSize
        )
        undoStack.append(currentState)
        apply(state: lastState)
    }
    
    
    private func apply(state: EditingState) {
        lines = state.lines
        lineWidth = state.lineWidth
        imageSize = state.imageSize
    }
    
    func canUndo() -> Bool {
        !undoStack.isEmpty
    }
    
    func canRedo() -> Bool {
        !redoStack.isEmpty
    }
    
    func renderLinesToImage() -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = UIScreen.main.scale
        
        let renderer = UIGraphicsImageRenderer(size: imageSize, format: format)
        
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            cgContext.setFillColor(UIColor.clear.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: imageSize))
            
            cgContext.setLineCap(.round)
            cgContext.setLineJoin(.round)
            
            for line in lines {
                guard !line.points.isEmpty else { continue }
                let path = CGMutablePath()
                path.addLines(between: line.points)
                
                cgContext.addPath(path)
                let uiColor = UIColor(line.color)
                cgContext.setStrokeColor(uiColor.cgColor)
                cgContext.setLineWidth(CGFloat(lineWidth))
                cgContext.strokePath()
            }
        }
        return image
    }
}


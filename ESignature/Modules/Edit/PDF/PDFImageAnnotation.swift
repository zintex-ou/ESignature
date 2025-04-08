import PDFKit

class PDFImageAnnotation: PDFAnnotation {
    var image: UIImage?
    var rotation: CGFloat = 0.0
    
    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        guard let cgImage = image?.cgImage else { return }
        
        context.saveGState()
        
        context.draw(cgImage, in: bounds)
        context.restoreGState()
    }
}

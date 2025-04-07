import PDFKit

class PDFImageAnnotation: PDFAnnotation {
    var image: UIImage?
    var rotation: CGFloat = 0.0
    
    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        guard let image = self.image, let cgImage = image.cgImage else { return }
        context.saveGState()
         
        context.translateBy(x: bounds.origin.x, y: bounds.origin.y)
        
        let radians = rotation * .pi / 180.0
        let center = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: radians)
        context.translateBy(x: -center.x, y: -center.y)
        
        context.draw(cgImage, in: CGRect(origin: .zero, size: bounds.size))
        
        context.restoreGState()
    }
    
    override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(Double(rotation), forKey: "rotation")
        if let image = image, let imageData = image.pngData() {
            coder.encode(imageData, forKey: "imageData")
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        rotation = CGFloat(coder.decodeDouble(forKey: "rotation"))
        if let data = coder.decodeObject(forKey: "imageData") as? Data {
            self.image = UIImage(data: data)
        }
    }
    
    override init(bounds: CGRect, forType annotationType: PDFAnnotationSubtype, withProperties properties: [AnyHashable : Any]? = nil) {
        super.init(bounds: bounds, forType: annotationType, withProperties: properties)
    }
}

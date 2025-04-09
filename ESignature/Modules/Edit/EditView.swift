import SwiftUI
import PDFKit
import Combine
import ManySheets

// MARK: - UIImage Extension to Rotate an Image
extension UIImage {
    func rotated(by degrees: CGFloat) -> UIImage? {
        let radians = degrees * .pi / 180
        var newSize = CGRect(origin: .zero, size: self.size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size
        newSize.width = max(newSize.width, 1)
        newSize.height = max(newSize.height, 1)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        context.rotate(by: radians)
        self.draw(in: CGRect(x: -self.size.width / 2,
                             y: -self.size.height / 2,
                             width: self.size.width,
                             height: self.size.height))
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rotatedImage
    }
}

struct EditView: View {
    @ObservedObject var viewModel: EditViewModel
    @State private var circleLocation: CGPoint?
    @State private var dragOffset: CGSize = .zero
    @State private var rotationAngle: Double = 0.0
    @State private var pdfViewRef: PDFView?
    @State var isLoading: Bool = false
    
    private let heightScreen = UIScreen.main.bounds.height
    
    @State private var currentStampAnnotation: PDFAnnotation?
    @State private var rotationGestureStartAngle: Double?
    @State private var initialRotationAngle: Double = 0.0
    let bottomSheetStyle = DefaultBottomSheetStyle(backgroundColor: .cF7F7F7, cornerRadius: 16)
    
    init(viewModel: EditViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                navBar
                
                GeometryReader { geometry in
                    ZStack {
                        VStack(spacing: 0) {
                            
                            if let _ = viewModel.fileURL {
                                
                                Spacer()
                                
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
                        
                        if viewModel.editState {
                            overlayFrame(geometry: geometry)
                        }
                    }
                }
                
                tabBar
            }
            
            DefaultBottomSheet(
                isOpen: $viewModel.shouldShowStampSheet,
                style: bottomSheetStyle,
                options: [.enableHandleBar, .tapAwayToDismiss, .swipeToDismiss]
            ) {
                VStack(alignment: .leading, spacing: 0) {
                    StampSheetView(viewModel: viewModel)
                }
                .frame(maxHeight: 321)
                .buttonStyle(PlainButtonStyle())
                .transaction { transaction in
                    transaction.animation = nil
                }
            }
            
            DefaultBottomSheet(
                isOpen: $viewModel.shouldShowSignSheet,
                style: bottomSheetStyle,
                options: [.enableHandleBar, .tapAwayToDismiss, .swipeToDismiss]
            ) {
                VStack(alignment: .leading, spacing: 0) {
                    SignSheetView()
                        .environmentObject(viewModel)
                }
                .frame(maxHeight: 321)
                .buttonStyle(PlainButtonStyle())
                .transaction { transaction in
                    transaction.animation = nil
                }
            }
            
            DefaultBottomSheet(
                isOpen: $viewModel.shouldShowWatermarkSheet,
                style: bottomSheetStyle,
                options: [.enableHandleBar, .tapAwayToDismiss, .swipeToDismiss]
            ) {
                VStack(alignment: .leading, spacing: 0) {
                    WatermarkSheetView(viewModel: viewModel)
                }
                .frame(maxHeight: 321)
                .buttonStyle(PlainButtonStyle())
                .transaction { transaction in
                    transaction.animation = nil
                }
            }
        }
        .background(Color(.cF7F7F7))
        .transparentFullScreenCover(isPresented: $viewModel.shouldShowTextEditor) {
            VStack {
                TextEditView()
                    .environmentObject(viewModel)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.c00000050))
        }
        .onAppear {
            viewModel.fetchStamps()
            viewModel.fetchSigns()
            viewModel.fetchWatermarks()
        }
        .photosPicker(isPresented: $viewModel.shouldShowGalleryStamp,
                      selection: $viewModel.stampItem,
                      matching: .images,
                      photoLibrary: .shared())
        .photosPicker(isPresented: $viewModel.shouldShowGallerySign,
                      selection: $viewModel.signItem,
                      matching: .images,
                      photoLibrary: .shared())
        .photosPicker(isPresented: $viewModel.shouldShowGalleryWatermark,
                      selection: $viewModel.watermarkItem,
                      matching: .images,
                      photoLibrary: .shared())
        .sheet(isPresented: $viewModel.shouldShowFileStamp) {
            DocumentPicker(pdfDocument: $viewModel.pdfDocument) { pdf in
                if let image = viewModel.pdfToImage(pdf: pdf) {
                    viewModel.loadStamp(uiImage: image)
                }
            }
        }
        .sheet(isPresented: $viewModel.shouldShowFileSign) {
            DocumentPicker(pdfDocument: $viewModel.pdfDocument) { pdf in
                if let image = viewModel.pdfToImage(pdf: pdf) {
                    viewModel.loadSign(uiImage: image, removeBack: true)
                }
            }
        }
        .sheet(isPresented: $viewModel.shouldShowFileWatermark) {
            DocumentPicker(pdfDocument: $viewModel.pdfDocument) { pdf in
                if let image = viewModel.pdfToImage(pdf: pdf) {
                    viewModel.loadWatermark(uiImage: image)
                }
            }
        }
        .onChange(of: viewModel.stampItem) { _ in
            viewModel.loadStampFromPhotos()
        }
        .onChange(of: viewModel.signItem) { _ in
            viewModel.loadSignFromPhotos()
        }
        .onChange(of: viewModel.watermarkItem) { _ in
            viewModel.loadWatermarkFromPhotos()
        }
        .ignoresSafeArea(.keyboard)
    }
    
    func addStampAtPointInPDF(image: UIImage, pointInPDFView: CGPoint, stampSize: CGSize) {
        guard let pdfView = self.pdfViewRef, let page = pdfView.currentPage else {
            return
        }
        
        let pdfPoint = pdfView.convert(pointInPDFView, to: page)
        let pdfScale = pdfView.scaleFactor
        
        let pdfStampSize = CGSize(width: stampSize.width / pdfScale,
                                  height: stampSize.height / pdfScale)
        
        let annotationRect = CGRect(
            x: pdfPoint.x - pdfStampSize.width / 2 - 25,
            y: pdfPoint.y - pdfStampSize.height / 2 - 10,
            width: pdfStampSize.width,
            height: pdfStampSize.height
        )
        
        print("PDF Point: \(pdfPoint)")
        print("Annotation Rect: \(annotationRect)")
        print("Page Bounds: \(page.bounds(for: .cropBox))")
        
        let annotation = PDFImageAnnotation(bounds: annotationRect, forType: .stamp, withProperties: nil)
        
        if
            let rotatedImage =  image.fixedOrientation().rotated(by: CGFloat(rotationAngle)) {
            annotation.image = rotatedImage
        } else {
            annotation.image = image.fixedOrientation()
        }
        
        annotation.rotation = CGFloat(rotationAngle)
        
        page.addAnnotation(annotation)
        pdfView.setNeedsDisplay()
    }
    
    func addWatermarkAtPointInPDF(image: UIImage, pointInPDFView: CGPoint, stampSize: CGSize) {
        guard let pdfView = self.pdfViewRef, let page = pdfView.currentPage else {
            return
        }
        
        let pdfPoint = pdfView.convert(pointInPDFView, to: page)
        let pdfScale = pdfView.scaleFactor
        
        let pdfStampSize = CGSize(width: stampSize.width / pdfScale,
                                  height: stampSize.height / pdfScale)
        
        let annotationRect = CGRect(
            x: pdfPoint.x - pdfStampSize.width / 2 - 25,
            y: pdfPoint.y - pdfStampSize.height / 2,
            width: pdfStampSize.width,
            height: pdfStampSize.height
        )
        
        print("PDF Point: \(pdfPoint)")
        print("Annotation Rect: \(annotationRect)")
        print("Page Bounds: \(page.bounds(for: .cropBox))")
        
        let annotation = PDFImageAnnotation(bounds: annotationRect, forType: .stamp, withProperties: nil)
        
        if
            let rotatedImage =  image.fixedOrientation().rotated(by: CGFloat(rotationAngle)) {
            annotation.image = rotatedImage
        } else {
            annotation.image = image.fixedOrientation()
        }
        
        annotation.rotation = CGFloat(rotationAngle)
        
        for pageImagex in 0...(pdfView.document?.pageCount ?? 1) {
            
            var nextPage = pdfView.document?.page(at: pageImagex)
            nextPage?.addAnnotation(annotation)
            print("pageImagex \(pageImagex)")
            
        }
        pdfView.setNeedsDisplay()
    }
    
    
    private func angleBetween(point: CGPoint, and center: CGPoint) -> Double {
        let deltaY = Double(point.y - center.y)
        let deltaX = Double(point.x - center.x)
        return atan2(deltaY, deltaX) * 180 / .pi
    }
    
    @ViewBuilder
    private func overlayFrame(geometry: GeometryProxy) -> some View {
        let defaultCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let currentCenter = CGPoint(
            x: (circleLocation?.x ?? geometry.size.width / 2) + dragOffset.width,
            y: (circleLocation?.y ?? geometry.size.height / 2) + dragOffset.height
        )
        
        if let image = viewModel.editImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: CGFloat(viewModel.twirlCircleRadius) * 2,
                       maxHeight: CGFloat(viewModel.twirlCircleRadius) * 2)
                .rotationEffect(.degrees(rotationAngle), anchor: .center)
                .overlay {
                    RoundedRectangle(cornerRadius: 12.47)
                        .stroke(Color(.c0666EB), style: StrokeStyle(lineWidth: 2, dash: [12, 8]))
                        .frame(width: CGFloat(viewModel.twirlCircleRadius) * 2,
                               height: CGFloat(viewModel.twirlCircleRadius) * 2)
                }
                .position(x: currentCenter.x, y: currentCenter.y)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let initialCenter = circleLocation ?? defaultCenter
                            dragOffset = CGSize(width: value.location.x - initialCenter.x,
                                                height: value.location.y - initialCenter.y)
                        }
                        .onEnded { _ in
                            var newLocation = CGPoint(
                                x: (circleLocation ?? defaultCenter).x + dragOffset.width,
                                y: (circleLocation ?? defaultCenter).y + dragOffset.height
                            )
                            
                            let circleRadius = CGFloat(viewModel.twirlCircleRadius)
                            let minX = circleRadius
                            let maxX = geometry.size.width - circleRadius
                            let minY = circleRadius
                            let maxY = geometry.size.height - circleRadius
                            
                            newLocation.x = min(max(newLocation.x, minX + 4), maxX - 2)
                            newLocation.y = min(max(newLocation.y, minY + 4), maxY - 2)
                            
                            circleLocation = newLocation
                            dragOffset = .zero
                        }
                )
                .contentShape(Rectangle())
            
            let absolutePos = currentCenter
            
            Circle()
                .fill(Color.c0666EB)
                .frame(width: 24, height: 24)
                .overlay {
                    Image(.rotationFrame)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }
                .position(
                    x: absolutePos.x + CGFloat(viewModel.twirlCircleRadius),
                    y: absolutePos.y - CGFloat(viewModel.twirlCircleRadius)
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let centerPoint = currentCenter
                            if rotationGestureStartAngle == nil {
                                rotationGestureStartAngle = angleBetween(point: value.startLocation, and: centerPoint)
                            }
                            let currentAngle = angleBetween(point: value.location, and: centerPoint)
                            let angleDelta = currentAngle - (rotationGestureStartAngle ?? currentAngle)
                            rotationAngle = initialRotationAngle + angleDelta
                        }
                        .onEnded { _ in
                            initialRotationAngle = rotationAngle
                            rotationGestureStartAngle = nil
                        }
                )
            
            Circle()
                .fill(Color.cDB341E)
                .frame(width: 24, height: 24)
                .overlay {
                    Image(.deleteFrame)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(.white)
                }
                .position(
                    x: absolutePos.x - CGFloat(viewModel.twirlCircleRadius),
                    y: absolutePos.y - CGFloat(viewModel.twirlCircleRadius)
                )
                .onTapGesture {
                    viewModel.editState = false
                }
            
            Circle()
                .fill(Color.c0666EB)
                .frame(width: 24, height: 24)
                .overlay {
                    Image(.scaleFrame)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }
                .position(
                    x: absolutePos.x + CGFloat(viewModel.twirlCircleRadius),
                    y: absolutePos.y + CGFloat(viewModel.twirlCircleRadius)
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let changeInRadius = value.translation.width + value.translation.height
                            viewModel.twirlCircleRadius += Float(changeInRadius * 0.02)
                            viewModel.twirlCircleRadius = max(30, min(viewModel.twirlCircleRadius, Float(min(geometry.size.width, geometry.size.height)) / 2))
                        }
                        .onEnded { _ in
                            var newLocation = CGPoint(
                                x: (circleLocation ?? defaultCenter).x + dragOffset.width,
                                y: (circleLocation ?? defaultCenter).y + dragOffset.height
                            )
                            
                            let circleRadius = CGFloat(viewModel.twirlCircleRadius)
                            let minX = circleRadius
                            let maxX = geometry.size.width - circleRadius
                            let minY = circleRadius
                            let maxY = geometry.size.height - circleRadius
                            
                            newLocation.x = min(max(newLocation.x, minX + 4), maxX - 2)
                            newLocation.y = min(max(newLocation.y, minY + 4), maxY - 2)
                            
                            circleLocation = newLocation
                            dragOffset = .zero
                        }
                )
        }
    }
    
    @ViewBuilder
    private var tabBar: some View {
        VStack {
            HStack(spacing: 16) {
                if viewModel.editState {
                    Button {
                        if let image = viewModel.editImage,
                           let location = circleLocation {
                            let point = CGPoint(x: location.x + dragOffset.width, y: location.y + dragOffset.height)
                            let adjustedSize = CGFloat(viewModel.twirlCircleRadius) * 2
                            if viewModel.editedOverlayType == .watermark {
                                addWatermarkAtPointInPDF(
                                    image: image,
                                    pointInPDFView: point,
                                    stampSize:  CGSize(width: adjustedSize, height: adjustedSize)
                                )
                            } else {
                                addStampAtPointInPDF(
                                    image: image,
                                    pointInPDFView: point,
                                    stampSize: CGSize(width: adjustedSize, height: adjustedSize)
                                )
                            }
                        }
                        viewModel.editState = false
                        viewModel.saveSigned(id: viewModel.documentID ?? "")
                        rotationAngle = 0.0
                    } label: {
                        Text(R.string.localizable.apply())
                            .font(.custom(R.font.outfitSemiBold, size: 16))
                    }
                    .buttonStyle(BlueButtonStyle())
                } else {
                    Spacer()
                    ToolButton(
                        icon: R.image.signIcon(),
                        label: R.string.localizable.signature(),
                        action: viewModel.tapOnSign
                    )
                    Spacer()
                    ToolButton(
                        icon: R.image.stampIcon(),
                        label: R.string.localizable.stamp(),
                        action: viewModel.tapOnStamp
                    )
                    Spacer()
                    ToolButton(
                        icon: R.image.textIcon(),
                        label: R.string.localizable.text(),
                        action: { viewModel.showTextEditor() }
                    )
                    Spacer()
                    ToolButton(
                        icon: R.image.watermarkIcon(),
                        label: R.string.localizable.watermark(),
                        action: { viewModel.tapOnWatermark() }
                    )
                    Spacer()
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(.white)
        }
    }
    
    @ViewBuilder
    private var navBar: some View {
        ZStack {
            Text("\(viewModel.pdfViewModel.currentPageIndex + 1) of \(String(describing: viewModel.pdfDocument?.pageCount ?? 0))")
                .font(.custom(R.font.outfitRegular, size: 14))
                .foregroundStyle(.c7C7C7C)
            HStack(spacing: 8) {
                Button {
                    viewModel.pop()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                        .frame(width: 24, height: 24)
                }
                
                Spacer()
                
                Button {
                    viewModel.showSave()
                    
                    
                } label: {
                    Text(R.string.localizable.save)
                        .font(.custom(R.font.outfitSemiBold, size: 14))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .background(.c0666EB)
                .foregroundColor(.white)
                .cornerRadius(24)
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
    }
}

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
    @State private var pdfViewFrame: CGRect = .zero
    @State var isLoading: Bool = false
    @State private var currentStampAnnotation: PDFAnnotation?
    
    private let heightScreen = UIScreen.main.bounds.height
    
    let bottomSheetStyle = DefaultBottomSheetStyle(backgroundColor: .cF7F7F7, cornerRadius: 16)
    
    init(viewModel: EditViewModel) {
        self.viewModel = viewModel
    }
    
    private struct PDFViewFramePreferenceKey: PreferenceKey {
        static var defaultValue: CGRect = .zero
        static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
            value = nextValue()
        }
    }
    
    private func clampedOverlayCenter(_ point: CGPoint, radius: CGFloat) -> CGPoint {
        guard pdfViewFrame != .zero else { return point }
        
        let minX = pdfViewFrame.minX + radius
        let maxX = pdfViewFrame.maxX - radius
        let minY = pdfViewFrame.minY + radius
        let maxY = pdfViewFrame.maxY - radius
        
        return CGPoint(
            x: min(max(point.x, minX), maxX),
            y: min(max(point.y, minY), maxY)
        )
    }
    
    private func maxAllowedRadius(in geometry: GeometryProxy) -> CGFloat {
        if pdfViewFrame == .zero {
            return min(geometry.size.width, geometry.size.height) / 2
        }
        return min(pdfViewFrame.width, pdfViewFrame.height) / 2
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
                                    .background(
                                        GeometryReader { proxy in
                                            Color.clear
                                                .onAppear {
                                                    pdfViewFrame = proxy.frame(in: .named("editArea"))
                                                }
                                                .onChange(of: proxy.frame(in: .named("editArea"))) { newValue in
                                                    pdfViewFrame = newValue
                                                }
                                        }
                                    )
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
                        
                        VStack {
                            Spacer()
                            if viewModel.isLoading {
                                CustomLoaderView()
                                    .zIndex(1)
                            }
                            Spacer()
                        }
                        
                        if viewModel.editState {
                            overlayFrame(geometry: geometry)
                        }
                    }
                    .coordinateSpace(name: "editArea")
                    .onPreferenceChange(PDFViewFramePreferenceKey.self) { value in
                        pdfViewFrame = value
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
            viewModel.fetchOverlays()
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
        .onChange(of: viewModel.shouldShowStampSheet) { isOpen in
            if !isOpen {
                viewModel.clearOverlaySelection()
            }
        }
        .onChange(of: viewModel.shouldShowSignSheet) { isOpen in
            if !isOpen {
                viewModel.clearOverlaySelection()
            }
        }
        .onChange(of: viewModel.shouldShowWatermarkSheet) { isOpen in
            if !isOpen {
                viewModel.clearOverlaySelection()
            }
        }
        .ignoresSafeArea(.keyboard)
    }
    
    func addStampAtPointInPDF(image: UIImage, pointInEditor: CGPoint, stampSize: CGSize) {
        guard let pdfView = pdfViewRef,
              let page = pdfView.currentPage else {
            return
        }
        
        let pointInPDFView = CGPoint(
            x: pointInEditor.x - pdfViewFrame.minX,
            y: pointInEditor.y - pdfViewFrame.minY
        )
        
        guard pdfView.bounds.contains(pointInPDFView) else {
            print("Point outside PDFView bounds: \(pointInPDFView)")
            return
        }
        
        let pdfPoint = pdfView.convert(pointInPDFView, to: page)
        let pdfScale = pdfView.scaleFactor
        
        let pdfStampSize = CGSize(
            width: stampSize.width / pdfScale,
            height: stampSize.height / pdfScale
        )
        
        let annotationRect = CGRect(
            x: pdfPoint.x - pdfStampSize.width / 2,
            y: pdfPoint.y - pdfStampSize.height / 2,
            width: pdfStampSize.width,
            height: pdfStampSize.height
        )
        
        let annotation = PDFImageAnnotation(bounds: annotationRect, forType: .stamp, withProperties: nil)
        
        if let rotatedImage = image.fixedOrientation().rotated(by: CGFloat(rotationAngle)) {
            annotation.image = rotatedImage
        } else {
            annotation.image = image.fixedOrientation()
        }
        
        page.addAnnotation(annotation)
        pdfView.setNeedsDisplay()
    }
    
    func addWatermarkAtPointInPDF(image: UIImage, pointInEditor: CGPoint, stampSize: CGSize) {
        guard let pdfView = pdfViewRef,
              let document = pdfView.document else {
            return
        }
        
        let pointInPDFView = CGPoint(
            x: pointInEditor.x - pdfViewFrame.minX,
            y: pointInEditor.y - pdfViewFrame.minY
        )
        
        let pdfScale = pdfView.scaleFactor
        
        let pdfStampSize = CGSize(
            width: stampSize.width / pdfScale,
            height: stampSize.height / pdfScale
        )
        
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            
            let pdfPoint = pdfView.convert(pointInPDFView, to: page)
            
            let annotationRect = CGRect(
                x: pdfPoint.x - pdfStampSize.width / 2,
                y: pdfPoint.y - pdfStampSize.height / 2,
                width: pdfStampSize.width,
                height: pdfStampSize.height
            )
            
            let annotation = PDFImageAnnotation(bounds: annotationRect, forType: .stamp, withProperties: nil)
            
            if let rotatedImage = image.fixedOrientation().rotated(by: CGFloat(rotationAngle)) {
                annotation.image = rotatedImage
            } else {
                annotation.image = image.fixedOrientation()
            }
            
            page.addAnnotation(annotation)
        }
        
        pdfView.setNeedsDisplay()
    }
    
    @ViewBuilder
    private func overlayFrame(geometry: GeometryProxy) -> some View {
        let defaultCenter = CGPoint(
            x: pdfViewFrame == .zero ? geometry.size.width / 2 : pdfViewFrame.midX,
            y: pdfViewFrame == .zero ? geometry.size.height / 2 : pdfViewFrame.midY
        )
        let rawCenter = CGPoint(
            x: (circleLocation?.x ?? defaultCenter.x) + dragOffset.width,
            y: (circleLocation?.y ?? defaultCenter.y) + dragOffset.height
        )
        
        let currentCenter = clampedOverlayCenter(
            rawCenter,
            radius: CGFloat(viewModel.twirlCircleRadius)
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
                            let proposed = CGPoint(
                                x: initialCenter.x + value.translation.width,
                                y: initialCenter.y + value.translation.height
                            )
                            let clamped = clampedOverlayCenter(proposed, radius: CGFloat(viewModel.twirlCircleRadius))
                            dragOffset = CGSize(width: clamped.x - initialCenter.x,
                                                height: clamped.y - initialCenter.y)
                        }
                        .onEnded { _ in
                            let initialCenter = circleLocation ?? defaultCenter
                            let proposed = CGPoint(
                                x: initialCenter.x + dragOffset.width,
                                y: initialCenter.y + dragOffset.height
                            )
                            circleLocation = clampedOverlayCenter(proposed, radius: CGFloat(viewModel.twirlCircleRadius))
                            dragOffset = .zero
                            viewModel.setOverlayPosition = true
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
                .contentShape(Rectangle())
                .frame(width: 44, height: 44)
                .position(
                    x: absolutePos.x + CGFloat(viewModel.twirlCircleRadius),
                    y: absolutePos.y - CGFloat(viewModel.twirlCircleRadius)
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        rotationAngle += 90
                        
                        if rotationAngle >= 360 {
                            rotationAngle = 0
                        }
                    }
                }
            
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
                .contentShape(Rectangle())
                .frame(width: 44, height: 44)
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
                .contentShape(Rectangle())
                .frame(width: 44, height: 44)
                .position(
                    x: absolutePos.x + CGFloat(viewModel.twirlCircleRadius),
                    y: absolutePos.y + CGFloat(viewModel.twirlCircleRadius)
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let changeInRadius = value.translation.width + value.translation.height
                            viewModel.twirlCircleRadius += Float(changeInRadius * 0.02)
                            let maxRadius = maxAllowedRadius(in: geometry)
                            viewModel.twirlCircleRadius = max(30, min(viewModel.twirlCircleRadius, Float(maxRadius)))
                            let baseCenter = circleLocation ?? defaultCenter
                            circleLocation = clampedOverlayCenter(baseCenter, radius: CGFloat(viewModel.twirlCircleRadius))
                        }
                        .onEnded { _ in
                            let proposedLocation = CGPoint(
                                x: (circleLocation ?? defaultCenter).x + dragOffset.width,
                                y: (circleLocation ?? defaultCenter).y + dragOffset.height
                            )
                            
                            let circleRadius = CGFloat(viewModel.twirlCircleRadius)
                            let newLocation = clampedOverlayCenter(proposedLocation, radius: circleRadius)
                            
                            circleLocation = newLocation
                            dragOffset = .zero
                        }
                )
        }
    }
    
    @ViewBuilder
    private var tabBar: some View {
        ZStack {
                if viewModel.editState {
                    Button {
                        if let image = viewModel.editImage,
                           let location = circleLocation {
                            let point = CGPoint(x: location.x + dragOffset.width, y: location.y + dragOffset.height)
                            let adjustedSize = CGFloat(viewModel.twirlCircleRadius) * 2
                            if viewModel.editedOverlayType == .watermark {
                                addWatermarkAtPointInPDF(
                                    image: image,
                                    pointInEditor: point,
                                    stampSize: CGSize(width: adjustedSize, height: adjustedSize)
                                )
                            } else {
                                addStampAtPointInPDF(
                                    image: image,
                                    pointInEditor: point,
                                    stampSize: CGSize(width: adjustedSize, height: adjustedSize)
                                )
                            }
                        }
                        viewModel.editState = false
                        viewModel.setOverlayPosition = false
                        rotationAngle = 0.0
                        viewModel.saveSigned(id: viewModel.documentID)
                    } label: {
                        Text(R.string.localizable.apply())
                            .font(.custom(R.font.outfitSemiBold, size: 16))
                    }
                    .buttonStyle(BlueButtonStyle())
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                } else {
                    HStack(spacing: 16) {
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
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(.white)
            }
           
        }
    }
    
    @ViewBuilder
    private var navBar: some View {
        ZStack {
            if !viewModel.editState {
                Text("\(viewModel.pdfViewModel.currentPageIndex + 1) of \(String(describing: viewModel.pdfDocument?.pageCount ?? 0))")
                    .font(.custom(R.font.outfitRegular, size: 14))
                    .foregroundStyle(.c7C7C7C)
            }
            
            HStack(spacing: 8) {
                Button {
                    if viewModel.editState {
                        viewModel.editState = false
                    } else {
                        viewModel.pop()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                        .frame(width: 24, height: 24)
                }
                
                Spacer()
                
                
                if !viewModel.editState {
                    
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
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
    }
}

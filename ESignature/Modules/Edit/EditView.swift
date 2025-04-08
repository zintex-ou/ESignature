import SwiftUI
import PDFKit
import Combine
import ManySheets

struct EditView: View {
    @ObservedObject var viewModel: EditViewModel
    //    @StateObject var pdfViewModel: PDFViewModel
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
//            viewModel.onWatermarkAdded = { image, annotationFrame in
//                guard let pdfView = self.pdfViewRef else {
//                    print("PDFView not available")
//                    return
//                }
//                
//                
//                guard let document = pdfView.document, let page = document.page(at: 0) else {
//                    print("No document or first page available")
//                    return
//                }
//                 
//                let pageBounds = page.bounds(for: .mediaBox)
//                  
//                let watermarkWidth = annotationFrame.width
//                let watermarkHeight = annotationFrame.height 
//                var centeredFrame = CGRect(
//                    x: pageBounds.origin.x + (pageBounds.width - watermarkWidth) / 2,
//                    y: pageBounds.origin.y + (pageBounds.height - watermarkHeight) / 2,
//                    width: watermarkWidth,
//                    height: watermarkHeight
//                )
//                
//                if centeredFrame.minX < pageBounds.minX {
//                    centeredFrame.origin.x = pageBounds.minX
//                }
//                if centeredFrame.maxX > pageBounds.maxX {
//                    centeredFrame.origin.x = pageBounds.maxX - watermarkWidth
//                }
//                
//                if centeredFrame.minY < pageBounds.minY {
//                    centeredFrame.origin.y = pageBounds.minY
//                }
//                if centeredFrame.maxY > pageBounds.maxY {
//                    centeredFrame.origin.y = pageBounds.maxY - watermarkHeight
//                }
//                
//                let verticalOffset: CGFloat = -40.0
//                centeredFrame.origin.y = min(centeredFrame.origin.y + verticalOffset, pageBounds.maxY - watermarkHeight)
//                
//                if !pageBounds.contains(centeredFrame) {
//                    print("Warning: Computed watermark frame \(centeredFrame) is still outside page bounds \(pageBounds)")
//                } else {
//                    print("Watermark frame \(centeredFrame) is within page bounds \(pageBounds)")
//                }
//                 
//                let annotation = PDFImageAnnotation(bounds: centeredFrame, forType: .stamp, withProperties: nil)
//                annotation.image = image.fixedOrientation()
//                annotation.rotation = -CGFloat(page.rotation)
//                 
//                DispatchQueue.main.async {
//                    UIView.performWithoutAnimation {
//                        page.addAnnotation(annotation)
//                        pdfView.setNeedsDisplay()
//                    }
//                }
//                
//                print("Watermark annotation added at \(centeredFrame) on page with bounds \(pageBounds)")
//            }
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
     
    func addStampAtPointInPDF(image: UIImage, pointInView: CGPoint, stampSize: CGSize) {
        guard let pdfView = self.pdfViewRef, let page = pdfView.currentPage else {
            print("PDF view or current page not available")
            return
        }
        
        guard let document = pdfView.document, let page = pdfView.currentPage else {
            print("Document not ready")
            return
        }
         
        let orientedImage = image.fixedOrientation()
         
        let pdfPoint = pdfView.convert(pointInView, to: page)
         
        let annotationRect = CGRect(
            x: pdfPoint.x - stampSize.width / 2,
            y: pdfPoint.y - stampSize.height / 2,
            width: stampSize.width,
            height: stampSize.height
        )
        let annotation = PDFImageAnnotation(bounds: annotationRect, forType: .stamp, withProperties: nil)
        annotation.image = orientedImage
         
        annotation.rotation = -CGFloat(page.rotation)
        annotation.rotation = -rotationAngle
        
        let pageBounds = page.bounds(for: .cropBox)
        guard pageBounds.contains(annotationRect) else {
            print("Stamp is outside the page")
            return
        }
        
        let pageBounds2 = page.bounds(for: .mediaBox)
        print("Page bounds: \(pageBounds2)")
         
        page.addAnnotation(annotation)
        currentStampAnnotation = annotation
         
        pdfView.setNeedsDisplay()
        
        print("Overlay added at pdfPoint \(pdfPoint) with page rotation \(page.rotation)")
    }
    
    private func angleBetween(point: CGPoint, and center: CGPoint) -> Double {
        let deltaY = Double(point.y - center.y)
        let deltaX = Double(point.x - center.x)
        return atan2(deltaY, deltaX) * 180 / .pi
    }
    
    @ViewBuilder
    private func overlayFrame(geometry: GeometryProxy) -> some View {
        let defaultCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let location = circleLocation ?? defaultCenter
        let currentCenter = CGPoint(
            x: location.x + dragOffset.width,
            y: location.y + dragOffset.height
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
                                x: (circleLocation?.x ?? defaultCenter.x) + dragOffset.width,
                                y: (circleLocation?.y ?? defaultCenter.y) + dragOffset.height
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
                .overlay(
                    Image(.rotationFrame)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                )
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
                .overlay(
                    Image(.scaleFrame)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                )
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
                                x: (circleLocation?.x ?? defaultCenter.x) + dragOffset.width,
                                y: (circleLocation?.y ?? defaultCenter.y) + dragOffset.height
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
                        if let image = viewModel.editImage, let location = circleLocation {
                            let adjustedSize = CGFloat(viewModel.twirlCircleRadius) * 3
                            addStampAtPointInPDF(
                                image: image,
                                pointInView: location,
                                stampSize: CGSize(width: adjustedSize, height: adjustedSize)
                            )
                            viewModel.saveSigned(id: viewModel.documentID ?? "")
                        }
                        viewModel.editState = false
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
            Text("\(viewModel.pdfViewModel.currentPageIndex + 1) of \(String(describing: viewModel.pdfDocument?.pageCount ?? 0) )")
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

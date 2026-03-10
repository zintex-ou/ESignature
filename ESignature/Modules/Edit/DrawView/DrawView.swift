
import SwiftUI


struct DrawView: View {
    
    @EnvironmentObject var viewModel: EditViewModel
    
    var body: some View {
        ZStack {
            VStack {
                navBar
                
                canvas
                
                lineWidthSlider
                
                colorPicker
                
                Button {
                    saveDrawing()
                } label: {
                    Text(R.string.localizable.save())
                        .font(.custom(R.font.outfitSemiBold, size: 16))
                }
                .buttonStyle(BlueButtonStyle())
                .padding(.horizontal, 16)
                .padding(.top, 24)
                
                Spacer()
            }
        }
        .background(Color(.cF7F7F7))
        .onAppear {
            viewModel.lines.removeAll()
        }
    }
    
    @ViewBuilder
    private var navBar: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.dissmis()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.black)
                    .frame(width: 24, height: 24)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private var canvas: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 23.8)
                .fill(.white)
                .overlay {
                    Canvas { context, size in
                        for line in viewModel.lines {
                            var path = Path()
                            path.addLines(line.points)
                            
                            let strokeStyle = StrokeStyle(lineWidth: viewModel.lineWidth)
                            context.blendMode = .normal
                            context.stroke(path, with: .color(line.color), style: strokeStyle)
                        }
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { dragValue in
                            viewModel.saveState()
                            
                            if viewModel.lines.isEmpty {
                                viewModel.lines.append(Line(color: viewModel.drawingColor, points: []))
                            } else {
                                viewModel.lines[viewModel.lines.count - 1].points.append(dragValue.location)
                            }
                        }
                        .onEnded { _ in
                            
                            viewModel.lines.append(Line(color: viewModel.drawingColor, points: []))
                        }
                )
                .onAppear {
                    viewModel.imageSize = geometry.size
                }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }
    
    @ViewBuilder
    private var lineWidthSlider: some View {
        VStack {
            HStack(alignment: .center, spacing: 16) {
                Image(R.image.thinLineImage)
                    .resizable()
                    .frame(width: 24, height: 24)
                
                Slider(value: $viewModel.lineWidth, in: 0.1...10.0, step: 0.1)
                    .padding(.horizontal, 8)
                
                Image(R.image.boltLineImage)
                    .resizable()
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.bottom, 4)
        .padding(.top, 4)
        .frame(maxWidth: .infinity)
  
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }
    
    @ViewBuilder
    private var colorPicker: some View {
        
        ZStack {
            HStack(spacing: 16) {
                ForEach(ColorsEnum.allCases, id: \.self) { item in
                    Button {
                        viewModel.drawingColor = item.color
                    } label: {
                        Circle()
                            .fill(item.color)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(item.color == viewModel.drawingColor ? Color.white : Color.clear, lineWidth: 2)
                                    .frame(width: 22, height: 22)
                            )
                    }
                    .padding(.horizontal, 8)
                }
                
                ColorPicker("", selection: $viewModel.drawingColor)
                    .scaleEffect(CGSize(width: 1.1, height: 1.1))
                    .labelsHidden()
                    .padding(.leading)
            }
            .frame(height: 88)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
        .padding(.top, 32)
    }
    
    private func saveDrawing() {
        guard let image = viewModel.renderLinesToImage() else {
            
            return
        }
        viewModel.loadSign(uiImage: image, removeBack: false)
        viewModel.fetchSigns()
        viewModel.dissmis()
        
    }
}

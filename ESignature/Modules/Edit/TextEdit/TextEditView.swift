import SwiftUI
import PDFKit
import Combine

struct TextEditView: View, KeyboardReadable {
    @EnvironmentObject var viewModel: EditViewModel
    
    let minWidth: CGFloat = 120
    let maxWidth: CGFloat = 300
    
    @State var enteringText: String = ""
    @State private var isKeyboardVisible = false
    
    @State private var textColor: Color = .black
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack {
                navBar
                
                Spacer()
                
                let textWidth = measuredWidth(for: enteringText)
                let finalWidth = max(minWidth, min(textWidth, maxWidth))
                
                ZStack {
                    
                    TextField(R.string.localizable.addYourText(), text: $enteringText)
                        .padding(8)
                        .font(.system(size: 16).bold())
                        .foregroundStyle(textColor)
                        .multilineTextAlignment(.center)
                        .onReceive(keyboardPublisher) { newIsKeyboardVisible in
                            isKeyboardVisible = newIsKeyboardVisible
                        }
                    
                }
                .frame(width: finalWidth, height: 48)
                .padding(.horizontal, 16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .animation(.easeInOut, value: enteringText)
                
                Spacer()
                
            }
            VStack {
                Spacer()
                
                colorPicker
                    .opacity(isKeyboardVisible ? 1 : 0)
//                    .padding(.bottom, isKeyboardVisible ? 216 : 0)
            }
        }
    }
    
    @ViewBuilder
    private var navBar: some View {
        ZStack {
            HStack(spacing: 8) {
                Button {
                    viewModel.dissmis()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                }
                
                Spacer()
                
                Button {
                    viewModel.editImage = textToImage(drawText: enteringText)
                    viewModel.editState = true
                    viewModel.dissmis()
                } label: {
                    Text(R.string.localizable.done)
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
    
    @ViewBuilder
    private var colorPicker: some View {
        ZStack {
            HStack(spacing: 16) {
                ForEach(ColorsEnum.allCases, id: \.self) { item in
                    Button {
                        textColor = item.color
                    } label: {
                        Circle()
                            .fill(item.color)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(item.color == textColor ? Color.white : Color.clear, lineWidth: 2)
                                    .frame(width: 22, height: 22)
                            )
                    }
                    .padding(.horizontal, 8)
                }
                
                ColorPicker("", selection: $textColor)
                .scaleEffect(CGSize(width: 1.1, height: 1.1))
                .labelsHidden()
                .padding(.leading)
            }
            .frame(height: 72)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .background(.white)
    }
    
//    @ViewBuilder
//    private var colorPicker: some View {
//        
//        ZStack {
//            HStack(spacing: 16) {
//                ForEach(ColorsEnum.allCases, id: \.self) { item in
//                    Button {
//                        textColor = item
//                    } label: {
//                        Circle()
//                            .fill(item.color)
//                            .frame(width: 30, height: 30)
//                            .overlay(
//                                Circle()
//                                    .stroke(item.color == textColor.color ? Color.white : Color.clear, lineWidth: 2)
//                                    .frame(width: 22, height: 22)
//                            )
//                    }
//                    .padding(.horizontal, 8)
//                }
//                
//                ColorPicker("", selection: $textColor)
//                    .scaleEffect(CGSize(width: 1.1, height: 1.1))
//                    .labelsHidden()
//                    .padding(.leading)
//            }
//            .frame(height: 72)
//            .frame(maxWidth: .infinity)
//        }
//        .frame(maxWidth: .infinity)
//        .background(.white)
//    }
    
    func measuredWidth(for text: String) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 17)
        let attributes = [NSAttributedString.Key.font: font]
        let size = (text as NSString).size(withAttributes: attributes)
        return size.width + 16 * 2
    }
    
    
    func textToImage(drawText text: String, font: UIFont = .boldSystemFont(ofSize: 50), backgroundColor: UIColor = .clear, size: CGSize = CGSize(width: 300, height: 300)) -> UIImage {
        let textColor = UIColor(self.textColor)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
        
        return image
    }
}

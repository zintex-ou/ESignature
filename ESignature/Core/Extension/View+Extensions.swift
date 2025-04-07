import SwiftUI

extension View {
    static var navigationID: String {
        String(describing: self)
    }
    
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, apply: (Self) -> Content) -> some View {
        if condition {
            apply(self)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func ifLet<T>(_ value: T?, apply: (Self, T) -> some View) -> some View {
        if let value = value {
            apply(self, value)
        } else {
            self
        }
    }
    
    func transparentFullScreenCover<Content: View>(
        isPresented: Binding<Bool>,
        cornerRadius: CGFloat = 24,
        content: @escaping () -> Content
    ) -> some View {
        fullScreenCover(isPresented: isPresented) {
            ZStack {
                content()
            }
            .background(TransparentBackground())
        }
    }
}

struct TransparentBackground: UIViewRepresentable {
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}


import SwiftUI

struct PulseButtonView: ViewModifier {
    @State private var enablePulse: Bool = false
    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 0.5, paused: false)) { timeline in
            ZStack {
                content
                    .scaleEffect(enablePulse ? 0.9 : 1)
            }
            .onChange(of: timeline.date) { _ in
                withAnimation(.linear(duration: 0.5)) {
                    enablePulse.toggle()
                }
            }
        }
    }
}
extension View {
    @ViewBuilder
    func pulseButtonStyle(isAnimated: Bool) -> some View {
        if isAnimated {
            self.modifier(PulseButtonView())
        } else {
            self
        }
    }
}

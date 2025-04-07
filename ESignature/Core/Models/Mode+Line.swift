
import SwiftUI

enum Mode: Int {
    case draw
}

struct Line {
    var color: Color
    var points: [CGPoint]
}

struct EditingState {
    var lines: [Line]
    var lineWidth: CGFloat
    var imageSize: CGSize
}

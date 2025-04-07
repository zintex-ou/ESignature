
import SwiftUI

enum ColorsEnum: CaseIterable {
    case black
    case purple
    case blue

    var color: Color {
        switch self {
        case .black:
            return Color("c000")
        case .purple:
            return Color("c4D22B2")
        case .blue:
            return Color("c007AFF")
        }
    }

    static var allCases: [ColorsEnum] {
        return [.black, .purple, .blue]
    }
}

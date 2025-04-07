import Foundation
import SwiftUI

enum PurchaisesError: Error {
    case raw(title: String, subTitle: String)
    
    var title: String {
        switch self {
        case let .raw(title, _): return title
        }
    }
    
    var subTitle: String {
        switch self {
        case let .raw(_, subTitle): return subTitle
        }
    }
}

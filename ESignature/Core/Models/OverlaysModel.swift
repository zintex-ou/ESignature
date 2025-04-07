
import Foundation
import UIKit

struct OverlaysModel: Hashable, Identifiable {
    let id: UUID
    var name: String
    let image: UIImage?
    let type: OverlayEnum
}

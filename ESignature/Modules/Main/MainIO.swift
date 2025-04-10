import Foundation
import SwiftUI
import UIKit

protocol MainOutput: AnyObject {
    func showPaywall()
    func showPadPaywall()
    func showEdit(
        image: UIImage?,
        fileURL: URL?,
        fileName: String?,
        isHistory: Bool,
        documentID: String
    )
    
    func showScanner(scanResult: Binding<[UIImage]>)
    func showSettings()
}


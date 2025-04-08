import UIKit

protocol EditOutput: AnyObject {
    func pop()
    func showDraw(_ viewModel: EditViewModel)
    func dissmis()
    func showSave(
        image: UIImage?,
        fileURL: URL?,
        fileName: String?,
        isHistory: Bool
    )
}

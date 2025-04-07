
protocol EditOutput: AnyObject {
    func pop()
    func showDraw(_ viewModel: EditViewModel)
//    func showTextEdit(_ viewModel: EditViewModel)
    func dissmis()
}

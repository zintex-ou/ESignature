import UIKit
import SwiftUI

class Assembly {
    
    func makeMain(output: MainOutput) -> UIHostingController<MainView> {
        let mainView = MainView(viewModel: .init(output: output))
        let controller = UIHostingController(rootView: mainView)
        return controller
    }
    
    func makeOnboard(output: OnboardOutput, onComplete: @escaping () -> Void) -> UIHostingController<OnboardView> {
        let onboardView = OnboardView(viewModel: .init(output: output, onComplete: onComplete))
        let controller = UIHostingController(rootView: onboardView)
        return controller
    }
    
    func makePaywall(output: PaywallOutput) -> UIHostingController<PaywallView> {
        let paywallView = PaywallView(viewModel: .init(output: output))
        let controller = UIHostingController(rootView: paywallView)
        return controller
    }
    
    func makePadPaywall(output: PaywallOutput) -> UIHostingController<PadPaywallView> {
        let padPaywallView = PadPaywallView(viewModel: .init(output: output))
        let controller = UIHostingController(rootView: padPaywallView)
        return controller
    }
    
    func makeDraw(output: EditOutput, viewModel: EditViewModel) -> UIHostingController<some View> {
        let drawView = DrawView().environmentObject(viewModel)
        let controller = UIHostingController(rootView: drawView)
        return controller
    }
    
    func makeScanner(scanResult: Binding<[UIImage]>) -> UIHostingController<some View> {
        let scannerView = ScannerView(scanResult: scanResult)
        let controller = UIHostingController(rootView: scannerView)
        return controller
    }
    
    func makeSettings(output: SettingsOutput) -> UIHostingController<some View> {
        let settingsView = SettingsView(viewModel: .init(output: output))
        let controller = UIHostingController(rootView: settingsView)
        return controller
    }
    
    func makeAuth(output: AuthOutput) -> UIHostingController<some View> {
        let authView = AuthView(viewModel: .init(output: output))
        let controller = UIHostingController(rootView: authView)
        return controller
    }
    
    func makeResetPassword(output: ResetPasswordOutput) -> UIHostingController<some View> {
        let resetPasswordView = ResetPasswordView(viewModel: .init(output: output))
        let controller = UIHostingController(rootView: resetPasswordView)
        return controller
    }
    
    func makePassword(output: PasswordOutput, isPresent: Bool, onUnlockComplete: (() -> Void)?) -> UIHostingController<some View> {
        let passwordView = PasswordView(viewModel: .init(output: output, isPresent: isPresent, onUnlockComplete: onUnlockComplete))
        let controller = UIHostingController(rootView: passwordView)
        return controller
    }
    
    func makeEdit(
        output: EditOutput,
        image: UIImage?,
        imageName: String? = nil,
        fileURL: URL?,
        fileName: String?,
        isHistory: Bool,
        documentID: String
    ) -> UIHostingController<EditView> {
        let editView = EditView(viewModel: .init(
            output: output,
            image: image,
            imageName: imageName,
            fileURL: fileURL,
            isHistory: isHistory,
            documentID: documentID
        ))
        let controller = UIHostingController(rootView: editView)
        return controller
    }
    
    func makeSave(
        output: EditOutput,
        image: UIImage?,
        imageName: String? = nil,
        fileURL: URL?,
        fileName: String?,
        isHistory: Bool,
        documentID: String
    ) -> UIHostingController<some View> {
        let saveView = SaveView(viewModel: .init(
            output: output,
            image: image,
            imageName: imageName,
            fileURL: fileURL,
            isHistory: isHistory,
            documentID: documentID
        ))
        let controller = UIHostingController(rootView: saveView)
        return controller
    }
}

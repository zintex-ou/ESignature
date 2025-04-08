import UIKit
import MessageUI
import SwiftUI

final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
    private let assembly: Assembly
    private var navigationController: UINavigationController
    var window: UIWindow!
    
    private var isLaunchedBefore: Bool {
        get { UserDefaults.standard.bool(forKey: AppConstants.isLauchedBefore) }
        set { UserDefaults.standard.set(newValue, forKey: AppConstants.isLauchedBefore) }
    }
    
    init(
        assembly: Assembly,
        navigationController: UINavigationController,
        window: UIWindow
    ) {
        self.assembly = assembly
        self.navigationController = navigationController
        self.window = window
    }
    
    func start() {
        Task {
            await self.startFetching()
            await MainActor.run {
                guard isLaunchedBefore else {
                    self.startOnboard()
                    return
                }
                self.startMain()
            }
        }
        
    }
    
    func startFetching() async {
        await RemoteConfigProvider.shared.fetchConfig()
    }
    
    func startMain() {
        navigationController.setNavigationBarHidden(true, animated: false)
        let mainHost = assembly.makeMain(output: self)
        UserDefaults.standard.set(true, forKey: AppConstants.isLauchedBefore)
        navigationController.setViewControllers([mainHost], animated: true)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
    
    func startOnboard() {
        navigationController.setNavigationBarHidden(true, animated: false)
        let onboardHost = assembly.makeOnboard(
            output: self,
            onComplete: { [weak self] in
                self?.startMain()
            })
        navigationController.setViewControllers([onboardHost], animated: true)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
    
    
    func pop() {
        navigationController.popViewController(animated: true)
    }
    
    func popToRoot() {
        navigationController.popToRootViewController(animated: true)
    }
    
    func dissmis() {
        navigationController.dismiss(animated: true)
    }
    
    func checkPremium() -> Bool {
        return PurchaseManager.shared.isPremium
    }
    
    func addShortcutActionMenu() {
        guard checkPremium() else {
            UIApplication.shared.shortcutItems = []
            return
        }
        
        let shortcutItem = UIApplicationShortcutItem(
            type: "MailAction",
            localizedTitle: R.string.localizable.refundPayment(),
            localizedSubtitle: R.string.localizable.pleaseContactUsIfYouHaveAnIssue(),
            icon: UIApplicationShortcutIcon(type: .mail),
            userInfo: nil
        )
        UIApplication.shared.shortcutItems = [shortcutItem]
    }
    
    func openContactUs() {
        guard MFMailComposeViewController.canSendMail() else {
            let email = AppConstants.URLs.emailLink
            guard let url = URL(string: "mailto:\(email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
                showEmailErrorAlert()
                return
            }
            
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                showEmailClientNotFoundAlert(email: email)
            }
            return
        }
        
        let mailComposeVC = MFMailComposeViewController()
        mailComposeVC.setToRecipients([AppConstants.URLs.emailLink])
        mailComposeVC.setSubject(R.string.localizable.supportRequest())
        mailComposeVC.setMessageBody(R.string.localizable.pleaseDescribeYourIssueHere(), isHTML: false)
        mailComposeVC.mailComposeDelegate = self
        
        presentMailComposer(mailComposeVC)
    }
    
    private func showEmailErrorAlert() {
        let alert = UIAlertController(
            title: R.string.localizable.error(),
            message: R.string.localizable.unableToComposeEmail(),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presentAlert(alert)
    }
    
    private func showEmailClientNotFoundAlert(email: String) {
        let alert = UIAlertController(
            title: R.string.localizable.noEmailClient(),
            message: "\(R.string.localizable.pleaseInstallAMailAppOrContactUsAt()) \(email)",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: R.string.localizable.copyEmail(), style: .default) { _ in
            UIPasteboard.general.string = email
        })
        
        alert.addAction(UIAlertAction(title: R.string.localizable.cancel(), style: .cancel))
        
        presentAlert(alert)
    }
    
    private func presentMailComposer(_ controller: MFMailComposeViewController) {
        guard let topVC = UIApplication.getTopViewController() else {
            print("Error: Unable to get top view controller")
            return
        }
        
        if topVC.presentedViewController == nil {
            topVC.present(controller, animated: true)
        } else {
            topVC.dismiss(animated: true) {
                topVC.present(controller, animated: true)
            }
        }
    }
    
    private func presentAlert(_ alert: UIAlertController) {
        guard let topVC = UIApplication.getTopViewController() else {
            print("Error: Unable to present alert")
            return
        }
        topVC.present(alert, animated: true)
    }
    
}

// MARK: - MainOutput

extension Coordinator: MainOutput {
    func showPaywall() {
        if !checkPremium() {
            let paywallHost = assembly.makePaywall(output: self)
            paywallHost.modalPresentationStyle = .fullScreen
            navigationController.present(paywallHost, animated: true)
        }
    }
    
    func showPadPaywall() {
        let paywallHost = assembly.makePadPaywall(output: self)
        paywallHost.modalPresentationStyle = .overFullScreen
        paywallHost.view.backgroundColor = .clear
        
        navigationController.present(paywallHost, animated: true)
    }
    
    
    func showEdit(
        image: UIImage?,
        fileURL: URL?,
        fileName: String?,
        isHistory: Bool
    ) {
        let editHost = assembly.makeEdit(output: self, image: image, fileURL: fileURL, fileName: fileName, isHistory: isHistory)
        navigationController.pushViewController(editHost, animated: true)
    }
    
    func showScanner(scanResult: Binding<[UIImage]>) {
        let scannerHost = assembly.makeScanner(scanResult: scanResult)
        scannerHost.modalPresentationStyle = .fullScreen
        navigationController.present(scannerHost, animated: true)
    }
    
    func showSettings() {
        let settingsHost = assembly.makeSettings(output: self)
        navigationController.pushViewController(settingsHost, animated: true)
    }
}

// MARK: - OnboardOutput
extension Coordinator: OnboardOutput {
    
}

// MARK: - SettingsOutput

extension Coordinator: SettingsOutput {
    func showAuth() {
        let authHost = assembly.makeAuth(output: self)
        navigationController.pushViewController(authHost, animated: true)
    }
}

// MARK: - PaywallOutput

extension Coordinator: PaywallOutput {
    
}

// MARK: - EditOutput

extension Coordinator: EditOutput {
    func showDraw(_ viewModel: EditViewModel) {
        let drawHost = assembly.makeDraw(output: self, viewModel: viewModel)
        drawHost.modalPresentationStyle = .fullScreen
        navigationController.present(drawHost, animated: true)
    }
    
    func showSave(
        image: UIImage?,
        fileURL: URL?,
        fileName: String?,
        isHistory: Bool
    ) {
        let saveHost = assembly.makeSave(output: self, image: image, fileURL: fileURL, fileName: fileName, isHistory: isHistory)
        navigationController.pushViewController(saveHost, animated: true)
    }
}


// MARK: - AuthOutput

extension Coordinator: AuthOutput {
    func showResetPassword() {
        let resetPasswordHost = assembly.makeResetPassword(output: self)
        navigationController.pushViewController(resetPasswordHost, animated: true)
    }
    
    func showPasswordPresent() {
        let passwordHost = assembly.makePassword(output: self, isPresent: true)
        passwordHost.modalPresentationStyle = .fullScreen
        navigationController.present(passwordHost, animated: true)
    }
    
    func showPassword() {
        let passwordHost = assembly.makePassword(output: self, isPresent: false)
        navigationController.pushViewController(passwordHost, animated: true)
    }
}

// MARK: - ResetPasswordOutput

extension Coordinator: ResetPasswordOutput { }

// MARK: - PasswordOutput

extension Coordinator: PasswordOutput { }


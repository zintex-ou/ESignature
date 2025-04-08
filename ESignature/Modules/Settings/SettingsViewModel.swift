
import Foundation
import Combine
import UIKit
import StoreKit
import SwiftUI
import MessageUI

final class SettingsViewModel: NSObject, ObservableObject {
    weak var output: SettingsOutput?
    
    @Environment(\.openURL) var openURL
    
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false
    
    init(
        output: SettingsOutput?
    ) {
        self.output = output
    }
    
    func pop() {
        output?.pop()
    }
    
    @MainActor func handleTap(on item: SettingsEnum) {
        switch item {
            
        case .auth:
            showAuth()
            
        case .rate:
            requestReview()
            
        case .share:
            showShareApp()
            
        case .contact:
            openContactUs()
            
        case .terms:
            openTermsOfUse()
            
        case .privacy:
            openPrivacyPolicy()

        }
    }
    
    func showAuth() {
        output?.showAuth()
    }
    
    func showShareApp() {
        UIApplication.shared.shareApp()
    }
    
    func openPrivacyPolicy() {
        if let url = URL(string: AppConstants.URLs.privacyPolicy) {
            openURL(url)
        }
    }
    
    func openTermsOfUse() {
        if let url = URL(string: AppConstants.URLs.termsOfUse) {
            openURL(url)
        }
    }
    
    func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    func openContactUs() {
        if MFMailComposeViewController.canSendMail() {
            guard let url = URL(string: "mailto:\(AppConstants.URLs.emailLink)") else {
                showEmailErrorAlert()
                return
            }
            
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                showEmailClientNotFoundAlert()
            }
        } else {
            showEmailErrorAlert()
        }
    }
    
    private func showEmailErrorAlert() {
        showAlert(
            title: R.string.localizable.error(),
            message: R.string.localizable.unableToComposeEmail()
        )
    }
    
    private func showEmailClientNotFoundAlert() {
        showAlert(
            title: R.string.localizable.noEmailClient(),
            message: "\(R.string.localizable.pleaseInstallAMailAppOrContactUsAt()) \(AppConstants.URLs.emailLink)"
        )
    }
    
    func restorePurchases(completion: @escaping () -> Void) async {
    }
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            self.alertTitle = title
            self.alertMessage = message
            self.showAlert = true
        }
        
    }
}

extension SettingsViewModel: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        controller.dismiss(animated: true)
    }
}

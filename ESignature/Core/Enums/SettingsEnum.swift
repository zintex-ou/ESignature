
import SwiftUI

enum SettingsEnum: CaseIterable {
    case auth
    case rate
    case share
    case contact
    case privacy
    case terms
    
    var title: String {
        switch self {
        case .auth:
            R.string.localizable.authentication()
            
        case .rate:
            R.string.localizable.rateOurApp()

        case .share:
            R.string.localizable.shareApp()
            
        case .contact:
            R.string.localizable.contactUs()
            
        case .privacy:
            R.string.localizable.privacyPolicy()

        case .terms:
            R.string.localizable.termOfUse()

        }
    }
}

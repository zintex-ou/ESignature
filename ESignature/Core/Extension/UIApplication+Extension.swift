
import UIKit
import PDFKit

extension UIApplication {
    static func getTopViewController(base: UIViewController? =
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
            .first) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return getTopViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return getTopViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return base
    }
    
    var upViewController: UIViewController? {
       var topViewController = connectedScenes.compactMap {
         ($0 as? UIWindowScene)?.windows
           .filter { $0.isKeyWindow }
           .first?
           .rootViewController
       }
       .first
       if let presented = topViewController?.presentedViewController {
         topViewController = presented
       } else if let navController = topViewController as? UINavigationController {
         topViewController = navController.topViewController
       } else if let tabBarController = topViewController as? UITabBarController {
         topViewController = tabBarController.selectedViewController
       }
       return topViewController
     }
    
      func shareApp() {
          let textToShare: [Any] = [AppConstants.URLs.appStoreLink]
        let activityViewController = UIActivityViewController(
          activityItems: textToShare,
          applicationActivities: nil
        )
        if UIDevice.current.userInterfaceIdiom == .pad {
          guard let sourceView = upViewController?.view else { return }
          activityViewController.popoverPresentationController?.sourceView = sourceView
          activityViewController.popoverPresentationController?.sourceRect = CGRect(
            x: sourceView.bounds.midX,
            y: sourceView.bounds.midY,
            width: 0,
            height: 0
          )
          activityViewController.popoverPresentationController?.permittedArrowDirections = []
        }
        upViewController?.present(activityViewController, animated: true)
      }
    
    func shareFile(file: URL) {
        let textToShare: [Any] = [file]
      let activityViewController = UIActivityViewController(
        activityItems: textToShare,
        applicationActivities: nil
      )
      if UIDevice.current.userInterfaceIdiom == .pad {
        guard let sourceView = upViewController?.view else { return }
        activityViewController.popoverPresentationController?.sourceView = sourceView
        activityViewController.popoverPresentationController?.sourceRect = CGRect(
          x: sourceView.bounds.midX,
          y: sourceView.bounds.midY,
          width: 0,
          height: 0
        )
        activityViewController.popoverPresentationController?.permittedArrowDirections = []
      }
      upViewController?.present(activityViewController, animated: true)
    }
}

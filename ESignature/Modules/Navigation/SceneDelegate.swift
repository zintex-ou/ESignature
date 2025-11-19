
import UIKit
import FirebaseCore
import SwiftUI

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var shortCutItem: UIApplicationShortcutItem!
    private var keychainManager = KeychainManager()
    private let assembly = Assembly()
    private var coordinator: Coordinator!
        
    private let isPad = UIDevice.current.userInterfaceIdiom == .pad
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        FirebaseApp.configure()

        let navigationController = UINavigationController()
        self.coordinator = Coordinator(
            assembly: assembly,
            navigationController: navigationController,
            window: window
        )
        
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        coordinator.start()
        
        guard let shortCut = connectionOptions.shortcutItem else  { return }
        shortCutItem = shortCut
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        keychainManager.timeLock = Date()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        
        Task {
            await PurchaseManager.shared.fetchProfile()
            await MainActor.run {
                if UserDefaults.standard.bool(forKey: AppConstants.isLauchedBefore) {
                    coordinator.addShortcutActionMenu()
                    
                    if keychainManager.hasPassword ?? false {
                        if let topViewController = coordinator.navigationController.topViewController,
                           topViewController is UIHostingController<PasswordView> {
                            return
                        }
                        
                        if let lastLockDate = keychainManager.timeLock,
                           let gracePeriod = keychainManager.gracePeriod {
                            let timeElapsed = Date().timeIntervalSince(lastLockDate)
                            if timeElapsed < gracePeriod {
                                showPaywallIfNeeded()
                                return
                            }
                        }
                        
                        coordinator.showPasswordPresent(onUnlockComplete: { [weak self] in
                            self?.keychainManager.timeLock = Date()
                            self?.showPaywallIfNeeded()
                        })
                        
                        return
                    }
                    
                    showPaywallIfNeeded()
                }
            }
        }
    }

    private func showPaywallIfNeeded() {
        if !coordinator.checkPremium() {
            if isPad {
                coordinator.showPadPaywall()
            } else {
                coordinator.showPaywall()
            }
        }

        if let shortCutItem {
            _ = handle(shortcutItem: shortCutItem)
        }
    }
    
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let handled = handle(shortcutItem: shortcutItem)
        completionHandler(handled)
    }

    
    @discardableResult
    func handle(shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard shortcutItem.type == "MailAction" else { return false }
        
        coordinator.openContactUs()
        return true
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
    }

}

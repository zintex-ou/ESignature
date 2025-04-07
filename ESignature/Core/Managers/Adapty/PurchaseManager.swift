
import Foundation
import UIKit
import Adapty
import Combine

final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()
    
    @Published var isPremium: Bool = false
    @Published var availableProducts: [AdaptyPaywallProduct] = []
    
    private let keychainManager: KeychainManager = .init()
    private var userIdKey: String {
        if let userIdKey = self.keychainManager.userIdKey {
            return userIdKey
        } else {
            let userIdKey = UUID().uuidString
            keychainManager.userIdKey = userIdKey
            return userIdKey
        }
    }
    
    private init() {
        Adapty.activate("public_live_8s8HKTsE.bjldTl2hjMLgL2u46r0I",
                        customerUserId: userIdKey)
        
        self.isPremium = self.isActivityPurchases()
        
        Task {
            await fetchProfile()
        }
    }
    
    private func fetchProfile() async {
        do {
            let profile = try await Adapty.getProfile()
            saveExpiresPurchasesToStorage(profile: profile)
            await MainActor.run {
                isPremium = profile.accessLevels.contains(where: { $0.value.isActive })
            }
        } catch {
            guard let adaptyError = error as? AdaptyError else { return }
            print(adaptyError.description)
        }
    }
    
    private func saveExpiresPurchasesToStorage(profile: AdaptyProfile?) {
        guard let profile else { return }
        keychainManager.purchasesExpiresAt = profile.accessLevels["premium"]?.expiresAt
    }
    
    private func configureShortCut() {
        let shortcutItem = UIApplicationShortcutItem(
            type: "Contact mail",
            localizedTitle: R.string.localizable.stopSubscription(),
            localizedSubtitle: R.string.localizable.messageUsToLearnTheUnsubscribeProcess(),
            icon: UIApplicationShortcutIcon(type: .mail),
            userInfo: nil
        )
        UIApplication.shared.shortcutItems = [shortcutItem]
    }
    
    func fetchPaywall() async throws -> AdaptyPaywall {
        try await Adapty.getPaywall(placementId: "pdfsignature.electronic.doc.com.placement")
    }
    
    func fetchPaywallProducts(paywall: AdaptyPaywall) async throws -> [AdaptyPaywallProduct] {
        try await Adapty.logShowPaywall(paywall)
        print("logShowPaywall")

        let products = try await Adapty.getPaywallProducts(paywall: paywall)
        print("getPaywallProducts")

        await MainActor.run {
            availableProducts = products
            print("availableProducts")
        }
        return products
    }
    
    func makePurchase(product: AdaptyPaywallProduct) async throws -> AdaptyPurchaseResult {
        let purchasesResult = try await Adapty.makePurchase(product: product)
        saveExpiresPurchasesToStorage(profile: purchasesResult.profile)
        
        await MainActor.run {
            isPremium = purchasesResult.profile?.accessLevels.contains(where: { $0.value.isActive }) ?? false
        }
        
        return purchasesResult
    }
    
    func restorePurchases() async throws {
        let profile = try await Adapty.restorePurchases()
        saveExpiresPurchasesToStorage(profile: profile)
        await MainActor.run {
            isPremium = profile.accessLevels.contains(where: { $0.value.isActive })
        }
    }
    
    func isActivityPurchases() -> Bool {
        guard let expiresAt = self.keychainManager.purchasesExpiresAt else { return false }
        return Date() < expiresAt
    }
    
    func pricePerWeek(for product: AdaptyPaywallProduct) -> Decimal? {
        guard let subscriptionPeriod = product.subscriptionPeriod else {
            return nil
        }
        
        let totalPrice = product.price
        let numberOfWeeks: Int
        
        switch (subscriptionPeriod.unit, subscriptionPeriod.numberOfUnits) {
        case (.day, let value):
            numberOfWeeks = value / 7
        case (.week, let value):
            numberOfWeeks = value
        case (.month, let value):
            numberOfWeeks = value * 4
        case (.year, let value):
            numberOfWeeks = value * 52
        default:
            return nil
        }
        
        return numberOfWeeks > 0 ? totalPrice / Decimal(numberOfWeeks) : nil
    }

}

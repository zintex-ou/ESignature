import Foundation
import Adapty
import SwiftUI
import Reachability

final class PaywallViewModel: ObservableObject {
    weak var output: PaywallOutput?
    
    let purchaseManager = PurchaseManager.shared
    private let remoteConfig = RemoteConfigProvider.shared
    private var reachability: Reachability?
    
    @Published var cancell = false
    
    @Published var isLoading: Bool = false
    
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false
    
    @Published var disabledCloseButton: Bool = true
    @Published var continueButtonText: String = R.string.localizable.continue()
    @Published var adaptyProducts: [AdaptyPaywallProduct] = []
    @Published var paywallProducts: [PurchaiseProductModel] = []
    
    @Environment(\.openURL) var openURL
    
    var selectedProduct: PurchaiseProductModel? {
        paywallProducts.first(where: { $0.isSelected == true })
    }
    
    init(
        output: PaywallOutput?
    ) {
        self.output = output
        self.reachability = try? Reachability()
        self.paywallProducts = ProductFactory.createDefaultProducts()
        Task {
            await fetchPayWall()
        }
    }
    
    func dissmis() {
        output?.dissmis()
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
    
    func reviewStatus() -> Bool {
        print("review \(remoteConfig.isReview)")
        return remoteConfig.isReview
    }
    
    
    func selectPaywallProduct(product: PurchaiseProductModel) {
        paywallProducts.indices.forEach { index in
            paywallProducts[index].isSelected = (paywallProducts[index].id == product.id)
        }
    }
    
    var crossDisabledDuration: Double {
        return Double(remoteConfig.isReview ? 2 : 0)
    }
    
    func fetchPayWall() async {
        await setLoading(true)
        
        do {
            await remoteConfig.fetchConfig()
            let paywall = try await purchaseManager.fetchPaywall()
            await fetchPayWallProducts(paywall: paywall)
        } catch {
            handleError(error)
        }
        
        await setLoading(false)
    }
    
    func tapOnContinue(completion: @escaping () -> Void) {
        Task {
            await makePurchase(completion: completion)
        }
    }
    
    func tapOnRestore(completion: @escaping () -> Void) {
        Task {
            await restorePurchases(completion: completion)
        }
    }
    
}

extension PaywallViewModel {
    func continueButtonText(adaptyProduct: PurchaiseProductModel) -> String {
        if remoteConfig.isReview {
            
            let price = String(describing: adaptyProduct.price)
            let duration = adaptyProduct.timePeriod
            
            if !adaptyProduct.isFreeTrial {
                return "\(R.string.localizable.subscribeFor()) \(adaptyProduct.currency)\(price) / \(duration)"
            } else {
                return "\(R.string.localizable.with3DayTrialThen()) \(adaptyProduct.currency)\(price) / \(duration)"
            }
            
        } else {
            return R.string.localizable.continue()
        }
    }
    
    func descText(adaptyProduct: PurchaiseProductModel) -> String {
        
        let price = String(describing: adaptyProduct.price)
        let duration = adaptyProduct.timePeriod
        
        if !adaptyProduct.isFreeTrial {
            return "\(R.string.localizable.signShareAddStampsWatermarks()) \(adaptyProduct.currency)\(price) / \(duration)"
        } else {
            return "\(R.string.localizable.signShareAddStampsWatermarks()) \(adaptyProduct.currency)\(price) / \(duration) \(R.string.localizable.with3DayFreeTrial())"
        }
    }
    
    private func showNetworkError() {
        showAlert(
            title: R.string.localizable.badConnection(),
            message: R.string.localizable.pleaseTurnOnTheInternet()
        )
    }
    
    private func showGenericError() {
        showAlert(
            title: "Ooops...",
            message: "\(R.string.localizable.somethingWentWrong())\n\(R.string.localizable.pleaseTryAgain())"
        )
    }
    private func fetchPayWallProducts(paywall: AdaptyPaywall) async {
        await setLoading(true)
        
        do {
            let products = try await purchaseManager.fetchPaywallProducts(paywall: paywall)
            await MainActor.run {
                self.adaptyProducts = products
                self.paywallProducts = ProductFactory.createProducts(from: products)
                
                if self.paywallProducts.indices.contains(1) {
                    self.selectPaywallProduct(product: self.paywallProducts[1])
                } else if let firstProduct = self.paywallProducts.first {
                    self.selectPaywallProduct(product: firstProduct)
                }
            }
        } catch {
            handleError(error)
        }
        
        await setLoading(false)
    }
    
    
    func makePurchase(completion: @escaping () -> Void) async {
        print("makePurchase")
        guard reachability?.connection != .unavailable else {
            showNetworkError()
            return
        }
        
        guard let selectedProduct,
              let selectedAdaptyProduct = adaptyProducts
            .first(where: { $0.vendorProductId == selectedProduct.productId }) else {
            showGenericError()
            return
        }
        
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            let result = try await purchaseManager.makePurchase(product: selectedAdaptyProduct)
            
            switch result {
            case .userCancelled:
                if !remoteConfig.isReview {
                    await MainActor.run {
                        showAlert(
                            title: "Ooops...",
                            message: "\(R.string.localizable.somethingWentWrong())\n\(R.string.localizable.pleaseTryAgain())"
                        )
                        self.cancell = true
                    }
                } else {
                    showGenericError()
                }
            case .pending:
                break
            case .success:
                await MainActor.run {
                    self.cancell = false
                    completion()
                }
            }
        } catch {
            if AdaptyErrorManager.init(error: error).adaptyErrorCode == .paymentCancelled,
               !remoteConfig.isReview {
                await MainActor.run {
                    self.cancell = true
                }
                if let error = AdaptyErrorManager.init(error: error).error {
                    await MainActor.run {
                        showAlert(
                            title: error.title,
                            message: error.subTitle
                        )
                    }
                }
            } else {
                await MainActor.run {
                    self.cancell = false
                }
                if let error = AdaptyErrorManager.init(error: error).error {
                    showAlert(
                        title: error.title,
                        message: error.subTitle
                    )
                }
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    private func restorePurchases(completion: @escaping () -> Void) async {
        guard reachability?.connection != .unavailable else {
            showNetworkError()
            return
        }
        
        await setLoading(true)
        
        do {
            try await purchaseManager.restorePurchases()
            await MainActor.run {
                if purchaseManager.isPremium {
                    self.cancell = false
                    completion()
                } else {
                    self.cancell = false
                    showAlert(
                        title: R.string.localizable.noActiveSubscription(),
                        message: R.string.localizable.youHaveNoActiveSubscriptionsPleaseCheckYourSubscriptionStatus()
                    )
                }
            }
        } catch {
            handleError(error)
        }
        
        await setLoading(false)
    }
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            self.alertTitle = title
            self.alertMessage = message
            self.showAlert = true
        }
    }
    
    private func handleError(_ error: Error) {
        if let error = AdaptyErrorManager(error: error).error {
            showAlert(
                title: error.title,
                message: error.subTitle
            )
        }
    }
    
    @MainActor
    private func setLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }
    
    func pricePerWeek(_ product: PurchaiseProductModel) -> Decimal {
        guard let adaptyProduct = adaptyProducts.first(where: { $0.vendorProductId == product.productId }) else { return 0.0 }
        
        let price = purchaseManager.pricePerWeek(for: adaptyProduct) ?? 0.0
        return (price as NSDecimalNumber)
            .rounding(accordingToBehavior: NSDecimalNumberHandler(
                roundingMode: .plain,
                scale: 2,
                raiseOnExactness: false,
                raiseOnOverflow: false,
                raiseOnUnderflow: false,
                raiseOnDivideByZero: false
            )) as Decimal
    }
}

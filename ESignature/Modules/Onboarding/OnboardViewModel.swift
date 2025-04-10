
import Foundation
import SwiftUI
import Reachability
import Adapty
import StoreKit


final class OnboardViewModel: ObservableObject {
    weak var output: OnboardOutput?
    let onComplete: () -> Void
    
    private var reachability: Reachability?
    @ObservedObject private var remoteConfig = RemoteConfigProvider.shared
    private let purchaseManager = PurchaseManager.shared
    @Published var cancell = false
    
    @Environment(\.openURL) var openURL
    
    // MARK: - Published Properties
    @Published var isLoading: Bool = false
        
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false
    
    @Published var weeklyProduct: AdaptyPaywallProduct?
    @Published var continueButtonText: LocalizedStringResource = "Add area"
    
    init(
        output: OnboardOutput?,
        onComplete: @escaping () -> Void
    ) {
        self.output = output
        self.onComplete = onComplete
        Task { await fetchPayWall() }
        setupReachability()
    }
    
    deinit {
        reachability?.stopNotifier()
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
    
    func requestReview() {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    
    func getSubtitle() -> LocalizedStringResource {
        return "\(R.string.localizable.startWith3DayTrialThen()) \(priceText())."
        
    }
    
    func descText() -> String {
        let price = priceText()
     
        return "\(R.string.localizable.signShareAddStampsWatermarks()) \(String(describing: weeklyProduct?.currencySymbol ?? ""))\(String(describing: weeklyProduct?.price ?? 6.99)) / \(R.string.localizable.week()) \(R.string.localizable.with3DayFreeTrial())"
            }
    
    
    private func priceText() -> LocalizedStringResource {

        guard let adaptyProduct = weeklyProduct,
              let currency = adaptyProduct.currencySymbol else {
            return "$6.99/\(R.string.localizable.week())"
        }

        let price = String(format: "%.2f", NSDecimalNumber(decimal: adaptyProduct.price).floatValue)
        let period = !adaptyProduct.localizedDescription.isEmpty
            ? NSLocalizedString(adaptyProduct.localizedDescription, comment: "")
        : NSLocalizedString(R.string.localizable.week(), comment: "")

        if let introductoryDiscount = adaptyProduct.subscriptionOffer {
            return "\(currency)\(price)/\(period)"
        } else {
            return "\(currency)\(price)/\(period)"
        }
    }
    
    // MARK: - makePurchase

    func makePurchase(completion: @escaping () -> Void) async {
        guard isNetworkAvailable() else {
            showNetworkError()
            return
        }
        
        guard let weeklyProduct else {
            showGenericError()
            return
        }
        
        setLoading(true)
        
        do {
            let result = try await purchaseManager.makePurchase(product: weeklyProduct)
            
            switch result {
            case .userCancelled:
                await MainActor.run {
                    self.cancell = true
                }
                
                if remoteConfig.isReview {
                    await MainActor.run {
                        self.alertTitle = "Ooops..."
                        self.alertMessage =
                        "\(R.string.localizable.somethingWentWrong())\n\(R.string.localizable.pleaseTryAgain())"
                    }
                } else {
                    showGenericError()
                }
            case .pending:
                break
            case .success:
                handlePurchaseSuccess(completion: completion)
            }
        } catch {
            await handlePurchaseError(error)
        }
        
        setLoading(false)
    }
    
    func tapOnRestore(completion: @escaping () -> Void) {
        Task {
            await restorePurchases(completion: completion)
        }
    }
    
    // MARK: - Private Methods
    private func setupReachability() {
        reachability = try? Reachability()
        try? reachability?.startNotifier()
    }
    
    private func isNetworkAvailable() -> Bool {
        reachability?.connection != .unavailable
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
            message:
                "\(R.string.localizable.somethingWentWrong())\n\(R.string.localizable.pleaseTryAgain())"

        )
    }
    
    @MainActor
    private func setLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }
    
    @MainActor
    private func handlePurchaseSuccess(completion: () -> Void) {
        completion()
        onComplete()
    }
    
    private func handlePurchaseError(_ error: Error) async {
        let errorManager = AdaptyErrorManager(error: error)
        
        switch errorManager.adaptyErrorCode {
        case .paymentCancelled:
            showAlert(
                title: R.string.localizable.paymentCancelled(),
                message: R.string.localizable.youCancelledThePaymentProcess()
            )
        default:
            showAlert(
                title: R.string.localizable.error(),
                message: R.string.localizable.unknownError()
            )
        }
    }
    
    private func updateContinueButtonText() {
        guard remoteConfig.fetchComplete, let product = weeklyProduct else {
            continueButtonText = "Add area"
            return
        }
        
        continueButtonText = LocalizedStringResource(
            stringLiteral: formattedButtonText(for: product)
        )
    }
    
    private func formattedButtonText(for product: AdaptyPaywallProduct) -> String {
        guard let currency = product.currencySymbol else { return "\(R.string.localizable.subscribeFor()) $6.99/\(R.string.localizable.week())" }
        let price = NSDecimalNumber(decimal: product.price).stringValue
        
        let period = product.localizedSubscriptionPeriod ?? R.string.localizable.week()
        if let intro = product.subscriptionOffer {
            return "\(R.string.localizable.withA()) \(intro.subscriptionPeriod.numberOfUnits) \(R.string.localizable.dayTrialThen()) \(price) \(currency)/\(period)"
        } else {
            return "\(R.string.localizable.subscribeFor()) \(currency)\(price)/\(period)"
        }
    }

    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            self.alertTitle = title
            self.alertMessage = message
            self.showAlert = true
        }
    }
    
    private func fetchPayWallProducts(paywall: AdaptyPaywall) async {
        await MainActor.run {
            self.isLoading = true
        }
        do {
            let products = try await purchaseManager.fetchPaywallProducts(paywall: paywall)
            await MainActor.run {
                weeklyProduct = products.first
            }
        } catch {
            if let error = AdaptyErrorManager.init(error: error).error {
                showAlert(
                    title: error.title,
                    message: error.subTitle
                )
            }
        }
        await MainActor.run {
            self.isLoading = false
        }
    }
}


// MARK: - Purchase & Network Operations
extension OnboardViewModel {
  
    private func restorePurchases(completion: @escaping () -> Void) async {
        guard reachability?.connection != .unavailable else {
            showNetworkError()
            return
        }
        
        setLoading(true)
        
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
        
        setLoading(false)
    }
    
    private func fetchPayWall() async {
        setLoading(true)
        print("fetchPayWall")
        do {
            print("do")

            let paywall = try await purchaseManager.fetchPaywall()
            print("paywall")

            try await fetchPaywallProducts(paywall: paywall)

        } catch {
            if let purchaseError = error as? PurchaisesError {
                switch purchaseError {
                case .raw(let title, let subTitle):
                    print("\(title), \(subTitle)")
                }
            } else {
                print("Unknown error: \(error.localizedDescription)")
            }

        }
        
        setLoading(false)
    }
    
    private func fetchPaywallProducts(paywall: AdaptyPaywall) async throws {
        print("fetchPaywallProducts1")
        let products = try await purchaseManager.fetchPaywallProducts(paywall: paywall)
        print("fetchPaywallProducts2")

        await MainActor.run {
            weeklyProduct = products.first
            updateContinueButtonText()
        }
    }
    
    func reviewStatus() -> Bool {
        return remoteConfig.isReview
    }
    
    private func handleError(_ error: Error) {
        if let error = AdaptyErrorManager(error: error).error {
            showAlert(
                title: error.title,
                message: error.subTitle
            )
        }
    }
}



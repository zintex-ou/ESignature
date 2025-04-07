
import SwiftUI
import Adapty

struct ProductFactory {
    static func createDefaultProducts() -> [PurchaiseProductModel] {
        return [
         
            createProduct(
                vendorProductId: "",
                name: R.string.localizable.monthly(),
                price: 19.99, period: R.string.localizable.month(),
                isFreeTrial: false,
                trialDays: 0,
                type: .month
            ),
            
            createProduct(
                vendorProductId: "",
                name: R.string.localizable.weekly(),
                price: 1.99,
                period: R.string.localizable.week(),
                isFreeTrial: true,
                trialDays: 3,
                type: .week
            ),
            
            createProduct(
                vendorProductId: "",
                name: R.string.localizable.yearly(),
                price: 49.99,
                period: R.string.localizable.year(),
                isFreeTrial: false,
                trialDays: 0,
                type: .year
            )
        ]
    }
    
    static func createProducts(from adaptyProducts: [AdaptyPaywallProduct]) -> [PurchaiseProductModel] {
        return adaptyProducts.enumerated().map { index, product in
            var badgeText: String = ""
            var isFreeTrial: Bool = false
            var nameProduct: String = ""
            var period: String = ""
            var type: TypeSubscription = .week
            var trialDays = 0
            
            let localizedProductName = NSLocalizedString(product.localizedTitle, comment: "")
            
            switch product.localizedTitle {
            case "Monthly":
                nameProduct = NSLocalizedString(R.string.localizable.monthly(), comment: "")
                period = NSLocalizedString(R.string.localizable.month(), comment: "")
                type = .month
            case "Weekly":
                nameProduct = NSLocalizedString(R.string.localizable.weekly(), comment: "")
                period = NSLocalizedString(R.string.localizable.week(), comment: "")
                type = .week
            case "Yearly":
                nameProduct = NSLocalizedString(R.string.localizable.yearly(), comment: "")
                period = NSLocalizedString(R.string.localizable.year(), comment: "")
                type = .year
            default:
                break
            }
            
            if let subscriptionPeriod = product.subscriptionPeriod {
                let numberOfUnits = subscriptionPeriod.numberOfUnits
                let unit = subscriptionPeriod.unit
                
                if unit == .day {
                    trialDays = numberOfUnits
                    badgeText = "\(NSLocalizedString("days free trial", comment: ""))"
                }
            }
            
            isFreeTrial = product.subscriptionOffer?.offerType == .introductory
            return PurchaiseProductModel(
                productId: product.vendorProductId,
                nameProduct: localizedProductName,
                price: NSDecimalNumber(decimal: product.price).floatValue,
                currency: product.currencySymbol ?? "$",
                timePeriod: period,
                badgeText: badgeText,
                isFreeTrial: isFreeTrial,
                trialDays: trialDays,
                isSelected: false,
                type: type
            )
        }
    }
    
    private static func createProduct(vendorProductId: String, name: String, price: Float, period: String, isFreeTrial: Bool, trialDays: Int, type: TypeSubscription) -> PurchaiseProductModel {
        return PurchaiseProductModel(
            productId: vendorProductId,
            nameProduct: NSLocalizedString(name, comment: ""),
            price: price,
            currency: "$",
            timePeriod: "\(NSLocalizedString(period, comment: ""))",
            badgeText: isFreeTrial ? "\(NSLocalizedString("days free trial", comment: ""))" : nil,
            isFreeTrial: isFreeTrial,
            trialDays: trialDays,
            isSelected: type == .week,
            type: type
        )
    }
}

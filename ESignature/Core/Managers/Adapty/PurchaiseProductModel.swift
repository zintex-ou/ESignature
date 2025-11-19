
import Foundation

struct PurchaiseProductModel: Hashable, Codable, Identifiable {
    var id = UUID()
    let productId: String
    let nameProduct: String
    let price: Float
    let currency: String
    let timePeriod: String
    let badgeText: String?
    let isFreeTrial: Bool
    let trialDays: Int
    var isSelected: Bool
    let type: TypeSubscription
}

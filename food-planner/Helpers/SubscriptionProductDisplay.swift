import Adapty
import StoreKit

@MainActor
enum SubscriptionProductDisplay {
    enum PlanKind: Int, Comparable {
        case monthly = 0
        case annual = 1
        case lifetime = 2
        case other = 3

        static func < (lhs: PlanKind, rhs: PlanKind) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    static func kind(for product: AdaptyPaywallProduct) -> PlanKind {
        if let period = product.subscriptionPeriod {
            switch period.unit {
            case .year:
                return .annual
            case .month:
                return .monthly
            default:
                break
            }
        }

        if let storeProduct = StoreKitProductCatalog.product(for: product.vendorProductId),
           let period = storeProduct.subscription?.subscriptionPeriod {
            switch period.unit {
            case .year:
                return .annual
            case .month:
                return .monthly
            default:
                break
            }
        }

        if product.subscriptionPeriod == nil,
           StoreKitProductCatalog.product(for: product.vendorProductId)?.subscription == nil {
            return .lifetime
        }

        return .other
    }

    static func title(for product: AdaptyPaywallProduct) -> String {
        switch kind(for: product) {
        case .annual:
            return String(localized: "subscription.period.annual")
        case .monthly:
            return String(localized: "subscription.period.monthly")
        case .lifetime:
            return String(localized: "subscription.period.lifetime")
        case .other:
            break
        }

        if let period = product.subscriptionPeriod {
            switch period.unit {
            case .week:
                return String(localized: "subscription.period.weekly")
            case .day where period.numberOfUnits == 7:
                return String(localized: "subscription.period.weekly")
            default:
                break
            }
        }

        if let storeProduct = StoreKitProductCatalog.product(for: product.vendorProductId) {
            return storeProduct.displayName
        }

        return product.vendorProductId
    }

    static func periodLabel(for product: AdaptyPaywallProduct) -> String? {
        switch kind(for: product) {
        case .monthly:
            return String(localized: "subscription.plan.period.month")
        case .annual:
            return String(localized: "subscription.plan.period.year")
        case .lifetime:
            return String(localized: "subscription.plan.period.once")
        case .other:
            return nil
        }
    }

    static func price(for product: AdaptyPaywallProduct) -> String {
        if let storeProduct = StoreKitProductCatalog.product(for: product.vendorProductId) {
            return storeProduct.displayPrice
        }
        return product.localizedPrice ?? ""
    }

    static func periodDescription(dayCount: Int) -> String {
        "\(dayCount) \(SubscriptionPlural.dayUnit(count: dayCount))"
    }

    static func trialBadge(periodDescription: String) -> String {
        String(localized: "subscription.plan.badge.trial \(periodDescription)")
    }

    static func trialHint(periodDescription: String, priceLine: String) -> String {
        String(localized: "subscription.cta.trialHint \(periodDescription) \(priceLine)")
    }

    static func priceHint(periodDescription: String) -> String {
        String(localized: "home.proOffer.priceHint \(periodDescription)")
    }

    static func trialDescription(for product: AdaptyPaywallProduct) -> String? {
        if let storeProduct = StoreKitProductCatalog.product(for: product.vendorProductId),
           let offer = storeProduct.subscription?.introductoryOffer {
            let count = offer.periodCount * offer.period.value
            return "\(count) \(SubscriptionPlural.unit(offer.period.unit, count: count))"
        }

        if let discount = product.introductoryDiscount {
            let count = discount.numberOfPeriods * discount.subscriptionPeriod.numberOfUnits
            return "\(count) \(SubscriptionPlural.unit(discount.subscriptionPeriod.unit, count: count))"
        }

        return nil
    }

    static func sortedProducts(_ products: [AdaptyPaywallProduct]) -> [AdaptyPaywallProduct] {
        products.sorted { lhs, rhs in
            let left = kind(for: lhs)
            let right = kind(for: rhs)
            if left != right {
                return left < right
            }
            return lhs.vendorProductId < rhs.vendorProductId
        }
    }
}

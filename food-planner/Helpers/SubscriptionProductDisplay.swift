import Adapty
import StoreKit

@MainActor
enum SubscriptionProductDisplay {
    static func title(for product: AdaptyPaywallProduct) -> String {
        if let period = product.subscriptionPeriod {
            switch period.unit {
            case .year:
                return String(localized: "subscription.period.annual")
            case .month:
                return String(localized: "subscription.period.monthly")
            case .week:
                return String(localized: "subscription.period.weekly")
            case .day where period.numberOfUnits == 7:
                return String(localized: "subscription.period.weekly")
            case .day, .unknown:
                break
            }
        }

        if let storeProduct = StoreKitProductCatalog.product(for: product.vendorProductId) {
            return storeProduct.displayName
        }

        return product.vendorProductId
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
}

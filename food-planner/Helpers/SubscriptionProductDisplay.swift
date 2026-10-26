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

    static func subtitle(
        for product: AdaptyPaywallProduct,
        among products: [AdaptyPaywallProduct]
    ) -> String? {
        switch kind(for: product) {
        case .monthly:
            return String(localized: "subscription.plan.monthly.subtitle")
        case .annual:
            return annualSavingsSubtitle(among: products)
                ?? String(localized: "subscription.plan.annual.subtitle")
        case .lifetime:
            return String(localized: "subscription.plan.lifetime.subtitle")
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

    private static func annualSavingsSubtitle(among products: [AdaptyPaywallProduct]) -> String? {
        guard
            let monthly = products.first(where: { kind(for: $0) == .monthly }),
            let annual = products.first(where: { kind(for: $0) == .annual }),
            let monthlyStore = StoreKitProductCatalog.product(for: monthly.vendorProductId),
            let annualStore = StoreKitProductCatalog.product(for: annual.vendorProductId)
        else {
            return nil
        }

        let yearlyIfMonthly = monthlyStore.price * 12
        guard yearlyIfMonthly > 0, annualStore.price < yearlyIfMonthly else { return nil }

        let savingsRatio = (yearlyIfMonthly - annualStore.price) / yearlyIfMonthly
        let percent = Int((savingsRatio as NSDecimalNumber).doubleValue * 100.0)
        guard percent > 0 else { return nil }

        let perMonth = annualStore.price / 12
        let perMonthText = perMonth.formatted(annualStore.priceFormatStyle)
        return String(localized: "subscription.plan.annual.savings \(percent) \(perMonthText)")
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

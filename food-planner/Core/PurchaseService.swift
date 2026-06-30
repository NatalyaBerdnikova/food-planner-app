import Foundation
import SwiftUI
import Adapty

enum Placements: String {
    case basic = "basic_placement"
}

enum AccessLevels: String {
    case pro = "premium"
}

enum PurchaseService {
    static func getPaywall(
        placement: Placements,
        successCallback: @escaping (_ paywall: AdaptyPaywall) -> Void,
        errorCallback: @escaping (_ error: String) -> Void
    ) {
        Adapty.getPaywall(placementId: placement.rawValue, locale: Locale.current.language.languageCode?.identifier) { result in
            switch result {
            case let .success(paywall):
                successCallback(paywall)
                Adapty.logShowPaywall(paywall)
            case let .failure(error):
                print(error.debugDescription)
                errorCallback(error.localizedDescription)
            }
        }
    }

    static func getProducts(paywall: AdaptyPaywall, onLoad: @escaping (_ products: [AdaptyPaywallProduct]) -> Void) {
        Adapty.getPaywallProducts(paywall: paywall) { result in
            switch result {
            case let .success(products):
                onLoad(products)
            case let .failure(error):
                print(error.debugDescription)
                onLoad([])
            }
        }
    }

    static func getEligibilities(
        products: [AdaptyPaywallProduct],
        onLoad: @escaping (_ eligibilities: [String: AdaptyEligibility]) -> Void
    ) {
        Adapty.getProductsIntroductoryOfferEligibility(products: products) { result in
            switch result {
            case let .success(eligibilities):
                onLoad(eligibilities)
            case let .failure(error):
                print(error.debugDescription)
                onLoad([:])
            }
        }
    }

    static func makePurchase(
        product: AdaptyPaywallProduct,
        successCallback: @escaping (_ purchased: Bool) -> Void,
        errorCallback: @escaping (_ error: String) -> Void
    ) {
        Adapty.makePurchase(product: product) { result in
            switch result {
            case let .success(info):
                let purchased = info.profile.accessLevels[AccessLevels.pro.rawValue]?.isActive ?? false
                successCallback(purchased)
            case let .failure(error):
                print(error.debugDescription)
                errorCallback(error.localizedDescription)
            }
        }
    }

    static func restorePurchases(
        successCallback: @escaping (_ purchased: Bool) -> Void,
        errorCallback: @escaping (_ error: String) -> Void
    ) {
        Adapty.restorePurchases { result in
            switch result {
            case let .success(profile):
                let purchased = profile.accessLevels[AccessLevels.pro.rawValue]?.isActive ?? false
                successCallback(purchased)
            case let .failure(error):
                print(error.debugDescription)
                errorCallback(error.localizedDescription)
            }
        }
    }

    static func checkAccess(onUpdate: @escaping @MainActor (_ isPro: Bool) -> Void) {
        Adapty.getProfile { result in
            Task { @MainActor in
                if let profile = try? result.get(),
                   profile.accessLevels[AccessLevels.pro.rawValue]?.isActive ?? false {
                    onUpdate(true)
                } else {
                    onUpdate(false)
                }
            }
        }
    }

    static func canToggleTrial(_ eligibilities: [String: AdaptyEligibility]) -> Bool {
        let eligible = eligibilities.contains { _, value in value == .eligible }
        let notEligible = eligibilities.contains { _, value in value == .ineligible || value == .notApplicable }
        return eligible && notEligible
    }

    static func hasTrial(product: AdaptyPaywallProduct, eligibilities: [String: AdaptyEligibility]) -> Bool {
        eligibilities.contains { key, value in
            key == product.vendorProductId && value == .eligible
        }
    }

    static func getFirstEligibleProduct(
        products: [AdaptyPaywallProduct],
        eligibilities: [String: AdaptyEligibility]
    ) -> AdaptyPaywallProduct? {
        products.first { product in
            eligibilities.contains { key, value in
                key == product.vendorProductId && value == .eligible
            }
        }
    }

    static func getProfile(onLoad: @escaping (_ profile: AdaptyProfile?) -> Void) {
        Adapty.getProfile { result in
            switch result {
            case let .success(profile):
                onLoad(profile)
            case let .failure(error):
                print(error.debugDescription)
                onLoad(nil)
            }
        }
    }
}

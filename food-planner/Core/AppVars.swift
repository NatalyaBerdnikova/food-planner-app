import Foundation

enum AppVars {
    /// Public SDK key from the Adapty dashboard for Food Planner.
    static let adaptyToken = "public_live_nqpH0XUH.Kw9DNEH4MxjpIxxWNhy5"

    static let appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    static let termsUrl = "https://example.com/food-planner/terms"
    static let privacyUrl = "https://example.com/food-planner/privacy"

    /// TestFlight / pre-release: mock plans; Continue and Restore unlock Pro without StoreKit.
    static let useSubscriptionMocks = true
}

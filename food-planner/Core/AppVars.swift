import Foundation

enum AppVars {
    /// Public SDK key from the Adapty dashboard for Food Planner.
    static let adaptyToken = "public_live_REPLACE_WITH_FOOD_PLANNER_KEY"

    static let appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    static let termsUrl = "https://example.com/food-planner/terms"
    static let privacyUrl = "https://example.com/food-planner/privacy"
}

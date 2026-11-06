import Foundation

enum AppVars {
    /// Public SDK key from the Adapty dashboard for Food Planner.
    static let adaptyToken = "public_live_nqpH0XUH.Kw9DNEH4MxjpIxxWNhy5"

    static let appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    static let websiteBaseURLString = "https://food-planner.app"

    static var termsURL: URL { legalPageURL(path: "terms") }
    static var privacyURL: URL { legalPageURL(path: "privacy") }
    static var supportURL: URL { legalPageURL(path: "support") }
    static var deleteDataURL: URL { legalPageURL(path: "delete-data") }

    private static func legalPageURL(path: String) -> URL {
        let language = L10n.currentLanguageCode.hasPrefix("ru") ? "ru" : "en"
        return URL(string: "\(websiteBaseURLString)/\(language)/\(path)")!
    }

    /// TestFlight / pre-release: mock plans; Continue and Restore unlock Pro without StoreKit.
    static var useSubscriptionMocks: Bool {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return true
        }
        return false
    }

    /// Debug and TestFlight only: skip hard paywall without a purchase.
    static var allowsContinueWithoutSubscription: Bool {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return true
        }
        #if DEBUG
        return true
        #else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }
}

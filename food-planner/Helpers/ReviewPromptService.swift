import Foundation
import StoreKit
import SwiftUI

enum ReviewPromptService {
    private static let firstOpenDayKey = "reviewPrompt.firstOpenDay"
    private static let lastVersionKey = "reviewPrompt.lastVersion"
    private static let lastDateKey = "reviewPrompt.lastDate"
    private static let minimumDaysBetweenRequests = 14

    /// Remember the first calendar day the app was opened (for "not on day one" gating).
    static func noteAppOpen() {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: firstOpenDayKey) == nil else { return }
        defaults.set(Calendar.current.startOfDay(for: .now), forKey: firstOpenDayKey)
    }

    /// After a positive recipe signal (favorite on / star rating). Not on the first usage day.
    @MainActor
    static func considerAfterRecipeAppreciation(
        _ requestReview: RequestReviewAction,
        hasFullAccess: Bool
    ) {
        guard hasFullAccess else { return }
        noteAppOpen()
        guard hasPassedFirstUsageDay() else { return }
        guard canAskAgain() else { return }

        Task {
            try? await Task.sleep(for: .seconds(1.2))
            await requestReview()
            recordPromptShown()
        }
    }

    private static func hasPassedFirstUsageDay() -> Bool {
        guard let firstOpenDay = UserDefaults.standard.object(forKey: firstOpenDayKey) as? Date else {
            return false
        }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let firstDay = calendar.startOfDay(for: firstOpenDay)
        return today > firstDay
    }

    private static func canAskAgain() -> Bool {
        let defaults = UserDefaults.standard
        let version = currentAppVersion

        if defaults.string(forKey: lastVersionKey) == version {
            return false
        }

        if let lastDate = defaults.object(forKey: lastDateKey) as? Date {
            let days = Calendar.current.dateComponents([.day], from: lastDate, to: .now).day ?? 0
            if days < minimumDaysBetweenRequests {
                return false
            }
        }

        return true
    }

    private static func recordPromptShown() {
        let defaults = UserDefaults.standard
        defaults.set(currentAppVersion, forKey: lastVersionKey)
        defaults.set(Date(), forKey: lastDateKey)
    }

    private static var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
}

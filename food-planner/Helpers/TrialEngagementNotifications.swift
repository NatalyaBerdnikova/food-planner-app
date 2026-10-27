import Foundation
import UserNotifications
import Adapty

enum TrialEngagementNotifications {
    enum Kind: String, CaseIterable {
        case day1 = "trial.engagement.d1"
        case day3 = "trial.engagement.d3"
        case day7 = "trial.engagement.d7"
        case renewalMinus2 = "trial.engagement.renewalMinus2"

        var titleKey: String {
            switch self {
            case .day1: "notification.trial.d1.title"
            case .day3: "notification.trial.d3.title"
            case .day7: "notification.trial.d7.title"
            case .renewalMinus2: "notification.trial.renewalMinus2.title"
            }
        }

        var bodyKey: String {
            switch self {
            case .day1: "notification.trial.d1.body"
            case .day3: "notification.trial.d3.body"
            case .day7: "notification.trial.d7.body"
            case .renewalMinus2: "notification.trial.renewalMinus2.body"
            }
        }

        var deepLink: URL {
            switch self {
            case .day1, .day7:
                URL(string: "foodplanner://tab/plan")!
            case .day3, .renewalMinus2:
                URL(string: "foodplanner://tab/shopping")!
            }
        }
    }

    struct TrialWindow {
        let activatedAt: Date
        let expiresAt: Date?
    }

    private static let categoryID = "trial.engagement"
    private static let deepLinkKey = "deepLink"

    static func refreshFromAdapty() {
        PurchaseService.getProfile { profile in
            Task { @MainActor in
                guard let profile, let window = trialWindow(from: profile) else {
                    await cancelAll()
                    return
                }
                await sync(window: window)
            }
        }
    }

    /// TestFlight / mock unlock without Adapty trial metadata.
    static func scheduleSyntheticTrial(startingAt start: Date = .now, lastingDays: Int = 7) {
        Task { @MainActor in
            let expires = Calendar.current.date(byAdding: .day, value: lastingDays, to: start)
            await sync(window: TrialWindow(activatedAt: start, expiresAt: expires))
        }
    }

    @MainActor
    static func sync(window: TrialWindow) async {
        let center = UNUserNotificationCenter.current()
        registerCategoryIfNeeded()

        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                guard granted else { return }
            } catch {
                return
            }
        case .authorized, .provisional, .ephemeral:
            break
        default:
            return
        }

        await cancelAll()

        let now = Date()
        if let fire = daytime(onDayOffset: 1, from: window.activatedAt), fire > now {
            await schedule(.day1, at: fire)
        }
        if let fire = daytime(onDayOffset: 3, from: window.activatedAt), fire > now {
            await schedule(.day3, at: fire)
        }
        if let fire = daytime(onDayOffset: 7, from: window.activatedAt), fire > now {
            await schedule(.day7, at: fire)
        }
        if let expiresAt = window.expiresAt,
           let fire = daytime(on: expiresAt.addingTimeInterval(-2 * 24 * 60 * 60)),
           fire > now,
           fire < expiresAt {
            await schedule(.renewalMinus2, at: fire)
        }
    }

    static func cancelAll() async {
        let ids = Kind.allCases.map(\.rawValue)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)
    }

    static func trialWindow(from profile: AdaptyProfile) -> TrialWindow? {
        guard let level = profile.accessLevels[AccessLevels.pro.rawValue], level.isActive else {
            return nil
        }
        guard level.activeIntroductoryOfferType == "free_trial" else {
            return nil
        }
        return TrialWindow(activatedAt: level.activatedAt, expiresAt: level.expiresAt)
    }

    static func deepLink(from userInfo: [AnyHashable: Any]) -> URL? {
        guard let raw = userInfo[deepLinkKey] as? String else { return nil }
        return URL(string: raw)
    }

    private static func registerCategoryIfNeeded() {
        let category = UNNotificationCategory(
            identifier: categoryID,
            actions: [],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: String(localized: "notification.trial.previewPlaceholder"),
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    private static func schedule(_ kind: Kind, at date: Date) async {
        let content = UNMutableNotificationContent()
        content.title = String(localized: LocalizedStringResource(stringLiteral: kind.titleKey))
        content.body = String(localized: LocalizedStringResource(stringLiteral: kind.bodyKey))
        content.sound = .default
        content.categoryIdentifier = categoryID
        content.interruptionLevel = .active
        content.userInfo = [deepLinkKey: kind.deepLink.absoluteString]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: kind.rawValue, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("TrialEngagementNotifications: failed to schedule \(kind.rawValue): \(error)")
        }
    }

    private static func daytime(onDayOffset offset: Int, from start: Date) -> Date? {
        let calendar = Calendar.current
        guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: start)) else {
            return nil
        }
        return daytime(on: day)
    }

    private static func daytime(on date: Date) -> Date? {
        Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: date)
    }
}

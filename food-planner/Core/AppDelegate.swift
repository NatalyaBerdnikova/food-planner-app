import UIKit
import Adapty
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, AdaptyDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AppAnalytics.configureIfPossible()
        Adapty.delegate = self
        Adapty.activate(AppVars.adaptyToken)
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func didLoadLatestProfile(_ profile: AdaptyProfile) {
        let isPro = PurchaseService.isProAccessActive(in: profile)
        Task { @MainActor in
            PurchaseService.onProfileAccessChanged?(isPro)
            if let window = TrialEngagementNotifications.trialWindow(from: profile) {
                AppAnalytics.rememberTrialStart()
                AppAnalytics.setSubscriptionStatus("trial", planID: "none")
                await TrialEngagementNotifications.sync(window: window)
            } else if isPro {
                AppAnalytics.setSubscriptionStatus("active", planID: "none")
            } else {
                AppAnalytics.setSubscriptionStatus("none", planID: "none")
                await TrialEngagementNotifications.cancelAll()
            }
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        if let campaign = TrialEngagementNotifications.analyticsCampaign(from: userInfo) {
            AppAnalytics.logNotificationOpen(campaignID: campaign.id, day: campaign.day)
        }
        guard let url = TrialEngagementNotifications.deepLink(from: userInfo) else { return }
        await MainActor.run {
            DeepLinkBridge.open(url)
        }
    }
}

enum DeepLinkBridge {
    @MainActor
    static var openHandler: ((URL) -> Void)?

    @MainActor
    static func open(_ url: URL) {
        openHandler?(url)
    }
}

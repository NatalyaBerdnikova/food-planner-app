import UIKit
import Adapty
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, AdaptyDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
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
                await TrialEngagementNotifications.sync(window: window)
            } else if !isPro {
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
        guard let url = TrialEngagementNotifications.deepLink(
            from: response.notification.request.content.userInfo
        ) else { return }
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

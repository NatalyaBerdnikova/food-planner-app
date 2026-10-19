import UIKit
import Adapty

final class AppDelegate: NSObject, UIApplicationDelegate, AdaptyDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Adapty.delegate = self
        Adapty.activate(AppVars.adaptyToken)
        return true
    }

    func didLoadLatestProfile(_ profile: AdaptyProfile) {
        let isPro = PurchaseService.isProAccessActive(in: profile)
        Task { @MainActor in
            PurchaseService.onProfileAccessChanged?(isPro)
        }
    }
}

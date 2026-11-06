import UIKit

#if DEBUG
enum APIDebugStatusPresenter {
    @MainActor
    static func present(title: String, message: String) {
        guard let host = topViewController() else { return }

        if let existing = host.presentedViewController as? UIAlertController {
            existing.dismiss(animated: false) {
                presentAlert(on: host, title: title, message: message)
            }
            return
        }

        presentAlert(on: host, title: title, message: message)
    }

    @MainActor
    private static func presentAlert(on host: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        host.present(alert, animated: true)
    }

    @MainActor
    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
            ?? scenes.first?.windows.first
        var controller = window?.rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
        }
        return controller
    }
}
#endif

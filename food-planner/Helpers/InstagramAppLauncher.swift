import UIKit

enum InstagramAppLauncher {
    static func openApp() {
        open(candidates: [
            "instagram://",
            "https://www.instagram.com",
        ])
    }

    static func openSaved() {
        open(candidates: [
            "instagram://saved",
            "instagram://",
            "https://www.instagram.com",
        ])
    }

    private static func open(candidates: [String]) {
        for candidate in candidates {
            guard let url = URL(string: candidate) else { continue }
            if candidate.hasPrefix("http") || UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
    }
}

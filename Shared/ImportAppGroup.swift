import Foundation

enum ImportAppGroup {
    static let suiteName = "group.com.natalya-berdnikova.food-planner"
    static let pendingURLKey = "pendingImportURL"
    static let importURLScheme = "foodplanner"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static func savePendingImportURL(_ url: String) {
        guard let defaults = sharedDefaults else { return }
        defaults.set(url, forKey: pendingURLKey)
        defaults.synchronize()
    }

    static func peekPendingImportURL() -> String? {
        sharedDefaults?.string(forKey: pendingURLKey)
    }

    static func consumePendingImportURL() -> String? {
        guard let defaults = sharedDefaults else { return nil }
        let url = defaults.string(forKey: pendingURLKey)
        defaults.removeObject(forKey: pendingURLKey)
        defaults.synchronize()
        return url
    }

    static func importDeepLink(forInstagramURL urlString: String) -> URL? {
        var components = URLComponents()
        components.scheme = importURLScheme
        components.host = "import"
        components.queryItems = [URLQueryItem(name: "url", value: urlString)]
        return components.url
    }
}

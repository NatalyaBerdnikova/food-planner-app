import Foundation

enum ImportAppGroup {
    static let suiteName = "group.com.natalya-berdnikova.food-planner"
    static let pendingURLKey = "pendingImportURL"
    static let importURLScheme = "foodplanner"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static func savePendingImportURL(_ url: String) {
        sharedDefaults?.set(url, forKey: pendingURLKey)
    }

    static func consumePendingImportURL() -> String? {
        guard let defaults = sharedDefaults else { return nil }
        let url = defaults.string(forKey: pendingURLKey)
        defaults.removeObject(forKey: pendingURLKey)
        return url
    }
}

import Foundation

enum BackendAPIConfig {
    static let defaultBaseURLString = "https://food-planner.web-dev.su"

    static let baseURLKey = "FOOD_PLANNER_API_BASE_URL"
    static let ingestSecretKey = "FOOD_PLANNER_INGEST_SECRET"
    static let catalogRefreshIntervalHoursKey = "FOOD_PLANNER_CATALOG_REFRESH_HOURS"
    static let placeholderIngestSecret = "YOUR_FOOD_PLANNER_INGEST_SECRET"

    enum Path {
        static let catalogManifest = "/catalog/manifest.json"
        static let catalogRecipes = "/catalog/recipes.json"
        static let catalogFoods = "/catalog/foods.json"
        static let unmatchedIngredients = "/api/ingredients/unmatched"
    }

    static var baseURLString: String {
        let configured = ImportAPIConfig.resolvedString(
            forKey: baseURLKey,
            default: defaultBaseURLString
        )
        let trimmed = configured.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return defaultBaseURLString }
        return stripTrailingSlashes(trimmed)
    }

    static var baseURL: URL {
        URL(string: baseURLString) ?? URL(string: defaultBaseURLString)!
    }

    static var catalogManifestURL: URL {
        endpointURL(path: Path.catalogManifest)
    }

    static var catalogRecipesURL: URL {
        endpointURL(path: Path.catalogRecipes)
    }

    static var catalogFoodsURL: URL {
        endpointURL(path: Path.catalogFoods)
    }

    static var unmatchedIngredientsURL: URL {
        endpointURL(path: Path.unmatchedIngredients)
    }

    static var ingestSecret: String {
        let raw = ImportAPIConfig.resolvedString(forKey: ingestSecretKey, default: "")
        guard !raw.isEmpty,
              raw != placeholderIngestSecret,
              !raw.hasPrefix("$(") else {
            return ""
        }
        return raw
    }

    static var hasValidIngestSecret: Bool {
        !ingestSecret.isEmpty
    }

    static var catalogRefreshMinimumInterval: TimeInterval {
        let hours = ImportAPIConfig.resolvedDouble(forKey: catalogRefreshIntervalHoursKey, default: 6)
        return max(hours, 0.25) * 3600
    }

    static func endpointURL(path: String, baseURLString: String = Self.baseURLString) -> URL {
        let cleanBase = stripTrailingSlashes(baseURLString)
        let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
        if let url = URL(string: cleanBase + normalizedPath) {
            return url
        }
        return URL(string: defaultBaseURLString + normalizedPath)!
    }

    private static func stripTrailingSlashes(_ value: String) -> String {
        var result = value
        while result.hasSuffix("/") {
            result.removeLast()
        }
        return result
    }
}

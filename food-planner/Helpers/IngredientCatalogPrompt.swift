import Foundation

enum IngredientCatalogPrompt {
    private struct CatalogFile: Decodable {
        var products: [ProductEntry]
    }

    private struct ProductEntry: Decodable {
        var catalogKey: String
        var displayName: String?
        var translations: [String: String]?
    }

    private static var cachedPrompts: [String: String] = [:]
    private static var cachedKeys: [String]?
    private static let maxPromptCharacters = 24_000

    static func compactCatalog(languageCode: String = L10n.currentLanguageCode) -> String {
        let code = normalizedLanguageCode(languageCode)
        if let cached = cachedPrompts[code] {
            return cached
        }

        guard let url = Bundle.main.url(forResource: "food-catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(CatalogFile.self, from: data) else {
            cachedPrompts[code] = ""
            return ""
        }

        let prompt = file.products.map { entry in
            "\(entry.catalogKey) | \(localizedName(for: entry, languageCode: code))"
        }.joined(separator: "\n")

        cachedPrompts[code] = prompt
        return prompt
    }

    static func compactCatalogForPrompt(languageCode: String = L10n.currentLanguageCode) -> String {
        let full = compactCatalog(languageCode: languageCode)
        guard full.count > maxPromptCharacters else { return full }
        let truncated = String(full.prefix(maxPromptCharacters))
        if let lastNewline = truncated.lastIndex(of: "\n") {
            return String(truncated[..<lastNewline])
        }
        return truncated
    }

    static func allCatalogKeys() -> [String] {
        if let cachedKeys {
            return cachedKeys
        }

        guard let url = Bundle.main.url(forResource: "food-catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(CatalogFile.self, from: data) else {
            cachedKeys = []
            return []
        }

        let keys = file.products.map(\.catalogKey)
        cachedKeys = keys
        return keys
    }

    private static func normalizedLanguageCode(_ languageCode: String) -> String {
        languageCode.hasPrefix("ru") ? "ru" : "en"
    }

    private static func localizedName(for entry: ProductEntry, languageCode: String) -> String {
        if let translated = entry.translations?[languageCode], !translated.isEmpty {
            return translated
        }
        if languageCode.hasPrefix("ru"), let displayName = entry.displayName, !displayName.isEmpty {
            return displayName
        }
        if let english = entry.translations?["en"], !english.isEmpty {
            return english
        }
        return entry.displayName ?? entry.catalogKey
    }
}

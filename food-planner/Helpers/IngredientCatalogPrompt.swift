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

    private static var cachedPrompt: String?
    private static let maxPromptCharacters = 24_000

    static func compactCatalog() -> String {
        if let cachedPrompt { return cachedPrompt }

        guard let url = Bundle.main.url(forResource: "food-catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(CatalogFile.self, from: data) else {
            cachedPrompt = ""
            return ""
        }

        let lines = file.products.map { entry -> String in
            let ruName = localizedName(for: entry, languageCode: "ru")
            let enName = localizedName(for: entry, languageCode: "en")
            return "\(entry.catalogKey) | \(ruName) | \(enName)"
        }

        let prompt = lines.joined(separator: "\n")
        cachedPrompt = prompt
        return prompt
    }

    static func compactCatalogForPrompt() -> String {
        let full = compactCatalog()
        guard full.count > maxPromptCharacters else { return full }
        let truncated = String(full.prefix(maxPromptCharacters))
        if let lastNewline = truncated.lastIndex(of: "\n") {
            return String(truncated[..<lastNewline])
        }
        return truncated
    }

    static func allCatalogKeys() -> [String] {
        guard let url = Bundle.main.url(forResource: "food-catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(CatalogFile.self, from: data) else {
            return []
        }
        return file.products.map(\.catalogKey)
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

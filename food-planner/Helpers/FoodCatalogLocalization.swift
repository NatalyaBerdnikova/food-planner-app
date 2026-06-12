import Foundation

enum FoodCatalogLocalization {
    private struct CatalogFile: Decodable {
        var products: [ProductEntry]
    }

    private struct ProductEntry: Decodable {
        var catalogKey: String
        var displayName: String?
        var translations: [String: String]?
    }

    private static var namesByKey: [String: ProductEntry]?

    private static let supportedLanguageCodes = ["en", "ru"]

    static func name(for catalogKey: String, languageCode: String) -> String? {
        guard let entry = loadEntries()[catalogKey] else { return nil }

        if let translated = entry.translations?[languageCode], !translated.isEmpty {
            return translated
        }

        if languageCode.hasPrefix("ru"), let displayName = entry.displayName, !displayName.isEmpty {
            return displayName
        }

        if let english = entry.translations?["en"], !english.isEmpty {
            return english
        }

        return entry.displayName
    }

    static func matchesSearch(catalogKey: String, query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }

        return searchableTexts(for: catalogKey).contains {
            $0.localizedCaseInsensitiveContains(trimmed)
        }
    }

    static func searchableTexts(for catalogKey: String) -> [String] {
        var texts: Set<String> = [
            catalogKey,
            catalogKey.replacingOccurrences(of: "_", with: " "),
        ]

        if let entry = loadEntries()[catalogKey] {
            if let displayName = entry.displayName, !displayName.isEmpty {
                texts.insert(displayName)
            }
            entry.translations?.values
                .filter { !$0.isEmpty }
                .forEach { texts.insert($0) }
        }

        for code in supportedLanguageCodes {
            if let name = name(for: catalogKey, languageCode: code), !name.isEmpty {
                texts.insert(name)
            }
        }

        return Array(texts)
    }

    private static func loadEntries() -> [String: ProductEntry] {
        if let namesByKey {
            return namesByKey
        }

        guard let url = Bundle.main.url(forResource: "food-catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(CatalogFile.self, from: data) else {
            namesByKey = [:]
            return [:]
        }

        let map = Dictionary(uniqueKeysWithValues: file.products.map { ($0.catalogKey, $0) })
        namesByKey = map
        return map
    }
}

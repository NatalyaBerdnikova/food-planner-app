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
        let locale = languageCode.hasPrefix("ru") ? "ru" : "en"

        if let translated = entry.translations?[locale], !translated.isEmpty {
            return translated
        }

        if locale == "ru", let displayName = entry.displayName, !displayName.isEmpty {
            return displayName
        }

        return nil
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

    static func invalidateCache() {
        namesByKey = nil
    }

    private static func loadEntries() -> [String: ProductEntry] {
        if let namesByKey {
            return namesByKey
        }

        guard let data = RemoteCatalogSyncService.activeFoodsCatalogData(),
              let products = decodeProducts(from: data) else {
            namesByKey = [:]
            return [:]
        }

        let map = Dictionary(products.map { ($0.catalogKey, $0) }, uniquingKeysWith: { first, _ in first })
        namesByKey = map
        return map
    }

    private static func decodeProducts(from data: Data) -> [ProductEntry]? {
        if let file = try? JSONDecoder().decode(CatalogFile.self, from: data) {
            return file.products
        }
        if let array = try? JSONDecoder().decode([ProductEntry].self, from: data) {
            return array
        }
        return nil
    }
}

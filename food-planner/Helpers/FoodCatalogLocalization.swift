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

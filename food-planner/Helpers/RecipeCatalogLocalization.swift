import Foundation

enum RecipeCatalogLocalization {
    private struct CatalogFile: Decodable {
        var recipes: [RecipeEntry]
    }

    private struct RecipeEntry: Decodable {
        var id: String?
        var translations: [String: Translation]?
    }

    private struct Translation: Decodable {
        var name: String
        var steps: String
    }

    private static var entriesById: [String: RecipeEntry]?

    private static let supportedLanguageCodes = ["en", "ru"]

    static func name(for catalogRecipeId: String, languageCode: String) -> String? {
        translation(for: catalogRecipeId, languageCode: languageCode)?.name
    }

    static func steps(for catalogRecipeId: String, languageCode: String) -> String? {
        let steps = translation(for: catalogRecipeId, languageCode: languageCode)?.steps
        guard let steps, !steps.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return steps
    }

    static func matchesSearch(catalogRecipeId: String, query: String) -> Bool {
        matchesNameSearch(catalogRecipeId: catalogRecipeId, query: query)
    }

    static func matchesNameSearch(catalogRecipeId: String, query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }

        return searchableNameTexts(for: catalogRecipeId).contains {
            $0.localizedCaseInsensitiveContains(trimmed)
        }
    }

    static func searchableNameTexts(for catalogRecipeId: String) -> [String] {
        guard let entry = loadEntries()[catalogRecipeId] else { return [] }

        var texts: Set<String> = [catalogRecipeId]
        entry.translations?.values.forEach { translation in
            if !translation.name.isEmpty {
                texts.insert(translation.name)
            }
        }
        return Array(texts)
    }

    private static func translation(for catalogRecipeId: String, languageCode: String) -> Translation? {
        guard let entry = loadEntries()[catalogRecipeId],
              let translations = entry.translations else {
            return nil
        }

        if let translated = translations[languageCode], !translated.name.isEmpty {
            return translated
        }

        if languageCode.hasPrefix("ru"), let russian = translations["ru"], !russian.name.isEmpty {
            return russian
        }

        if let english = translations["en"], !english.name.isEmpty {
            return english
        }

        return translations.values.first
    }

    private static func loadEntries() -> [String: RecipeEntry] {
        if let entriesById {
            return entriesById
        }

        guard let url = Bundle.main.url(forResource: "recipes-catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(CatalogFile.self, from: data) else {
            entriesById = [:]
            return [:]
        }

        var map: [String: RecipeEntry] = [:]
        for recipe in file.recipes {
            guard let id = recipe.id?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty else {
                continue
            }
            map[id] = recipe
        }
        entriesById = map
        return map
    }
}

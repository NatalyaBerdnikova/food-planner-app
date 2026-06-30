import Foundation
import SwiftData

enum RecipeCatalogStore {
    private static let userFileName = "recipes-user.json"
    private static let appSupportFolder = "food-planner"

    struct CatalogFile: Codable {
        var version: Int?
        var recipes: [RecipeEntry]
    }

    struct RecipeEntry: Codable {
        struct IngredientEntry: Codable {
            var catalogKey: String
            var quantity: Double
            var unit: String
        }

        struct Translation: Codable {
            var name: String
            var steps: String
        }

        var id: String?
        var name: String?
        var servings: Int?
        var imageId: String?
        var imageBase64: String?
        var steps: [String]?
        var translations: [String: Translation]?
        var ingredients: [IngredientEntry]?
    }

    // MARK: - Public API

    /// Импортирует отсутствующие рецепты из bundle и пользовательского файла в SwiftData.
    @MainActor
    static func seedIfNeeded(in context: ModelContext) {
        importMissingRecipes(from: bundleCatalogURL(), isUserSource: false, in: context)
        importMissingRecipes(from: userCatalogURL(), isUserSource: true, in: context)
        LocalPersistence.save(context)
    }

    /// Сохраняет все пользовательские рецепты из SwiftData в файл на устройстве.
    @MainActor
    static func persistUserRecipes(in context: ModelContext) {
        let descriptor = FetchDescriptor<Recipe>()
        guard let all = try? context.fetch(descriptor) else { return }

        let userRecipes = all.filter(\.isUserCreated)
        for recipe in userRecipes where recipe.userRecipeId == nil {
            recipe.userRecipeId = UUID().uuidString
        }

        let existingById = loadExistingUserEntriesById()
        let entries = userRecipes.compactMap { makeEntry(from: $0, merging: existingById[$0.userRecipeId ?? ""]) }

        let file = CatalogFile(version: 2, recipes: entries)
        guard let data = try? JSONEncoder().encode(file) else { return }

        let url = userCatalogURL()
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: url, options: .atomic)
        LocalPersistence.save(context)
    }

    // MARK: - Import

    @MainActor
    private static func importMissingRecipes(
        from url: URL?,
        isUserSource: Bool,
        in context: ModelContext
    ) {
        guard let url,
              FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(CatalogFile.self, from: data) else {
            return
        }

        let existingCatalogIds = existingCatalogIds(in: context)
        let existingUserIds = existingUserIds(in: context)

        for item in catalog.recipes {
            let entryId = resolvedEntryId(for: item)
            guard !entryId.isEmpty else { continue }

            if isUserSource {
                guard !existingUserIds.contains(entryId),
                      let recipe = makeRecipe(from: item, userRecipeId: entryId, in: context) else {
                    continue
                }
                context.insert(recipe)
            } else {
                guard !existingCatalogIds.contains(entryId),
                      let recipe = makeRecipe(from: item, catalogId: entryId, in: context) else {
                    continue
                }
                context.insert(recipe)
            }
        }
    }

    @MainActor
    private static func existingCatalogIds(in context: ModelContext) -> Set<String> {
        let descriptor = FetchDescriptor<Recipe>()
        guard let all = try? context.fetch(descriptor) else { return [] }
        return Set(all.compactMap(\.catalogRecipeId))
    }

    @MainActor
    private static func existingUserIds(in context: ModelContext) -> Set<String> {
        let descriptor = FetchDescriptor<Recipe>()
        guard let all = try? context.fetch(descriptor) else { return [] }
        return Set(all.compactMap(\.userRecipeId))
    }

    @MainActor
    private static func makeRecipe(
        from item: RecipeEntry,
        catalogId: String,
        in context: ModelContext
    ) -> Recipe? {
        let name = resolvedName(from: item)
        guard !name.isEmpty else { return nil }

        let recipe = Recipe(
            name: name,
            catalogRecipeId: catalogId,
            servings: max(item.servings ?? 1, 1),
            imageData: loadImageData(for: item),
            steps: resolvedSteps(from: item)
        )
        replaceIngredients(for: recipe, from: item, in: context)
        recipe.recalculateNutrition()
        return recipe
    }

    @MainActor
    private static func makeRecipe(
        from item: RecipeEntry,
        userRecipeId: String,
        in context: ModelContext
    ) -> Recipe? {
        let name = resolvedName(from: item)
        guard !name.isEmpty else { return nil }

        let recipe = Recipe(
            name: name,
            userRecipeId: userRecipeId,
            servings: max(item.servings ?? 1, 1),
            imageData: loadImageData(for: item),
            steps: resolvedSteps(from: item)
        )
        replaceIngredients(for: recipe, from: item, in: context)
        recipe.recalculateNutrition()
        return recipe
    }

    @MainActor
    private static func replaceIngredients(
        for recipe: Recipe,
        from item: RecipeEntry,
        in context: ModelContext
    ) {
        recipe.ingredients = []

        for entry in item.ingredients ?? [] {
            guard let product = FoodCatalogSeeder.product(forKey: entry.catalogKey, in: context) else {
                continue
            }
            let unit = MeasurementUnit(rawValue: entry.unit) ?? .gram
            let ingredient = Ingredient(
                name: product.catalogKey,
                quantity: entry.quantity,
                unit: unit,
                category: product.category,
                recipe: recipe,
                foodProduct: product
            )
            context.insert(ingredient)
            recipe.ingredients.append(ingredient)
        }
    }

    // MARK: - Export

    private static func makeEntry(from recipe: Recipe, merging existing: RecipeEntry? = nil) -> RecipeEntry? {
        guard recipe.isUserCreated else { return nil }

        let ingredients = recipe.ingredients.compactMap { ingredient -> RecipeEntry.IngredientEntry? in
            let key = ingredient.foodProduct?.catalogKey ?? ingredient.name
            guard !key.isEmpty else { return nil }
            return RecipeEntry.IngredientEntry(
                catalogKey: key,
                quantity: ingredient.quantity,
                unit: ingredient.unit.rawValue
            )
        }

        let recipeId = recipe.userRecipeId ?? UUID().uuidString
        var translations = existing?.translations ?? [:]
        translations[L10n.currentLanguageCode] = RecipeEntry.Translation(
            name: recipe.name.trimmingCharacters(in: .whitespacesAndNewlines),
            steps: exportStepsText(from: recipe)
        )

        return RecipeEntry(
            id: recipeId,
            servings: recipe.servings,
            imageBase64: recipe.imageData?.base64EncodedString(),
            translations: translations,
            ingredients: ingredients
        )
    }

    private static func loadExistingUserEntriesById() -> [String: RecipeEntry] {
        let url = userCatalogURL()
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(CatalogFile.self, from: data) else {
            return [:]
        }

        var map: [String: RecipeEntry] = [:]
        for entry in catalog.recipes {
            let id = resolvedEntryId(for: entry)
            guard !id.isEmpty else { continue }
            map[id] = entry
        }
        return map
    }

    private static func exportStepsText(from recipe: Recipe) -> String {
        if let data = recipe.stepsRichTextData,
           let attributed = RecipeStepsStorage.attributedString(from: data) {
            let text = attributed.string.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                return text
            }
        }

        return recipe.steps
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    // MARK: - URLs

    private static func bundleCatalogURL() -> URL? {
        Bundle.main.url(forResource: "recipes-catalog", withExtension: "json")
    }

    static func userCatalogURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base
            .appendingPathComponent(appSupportFolder, isDirectory: true)
            .appendingPathComponent(userFileName)
    }

    // MARK: - Helpers

    private static func resolvedEntryId(for item: RecipeEntry) -> String {
        if let id = item.id?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty {
            return id
        }
        return resolvedName(from: item)
    }

    private static func resolvedTranslation(from item: RecipeEntry) -> RecipeEntry.Translation? {
        guard let translations = item.translations, !translations.isEmpty else { return nil }

        let preferred = L10n.currentLanguageCode
        if let translation = translations[preferred],
           !translation.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return translation
        }
        if let translation = translations["ru"],
           !translation.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return translation
        }
        if let translation = translations["en"],
           !translation.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return translation
        }
        return translations.values.first {
            !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private static func resolvedName(from item: RecipeEntry) -> String {
        if let translation = resolvedTranslation(from: item) {
            return translation.name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return item.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private static func resolvedSteps(from item: RecipeEntry) -> [String] {
        if let steps = resolvedTranslation(from: item)?.steps
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !steps.isEmpty {
            return [steps]
        }
        if let joined = item.steps?
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .filter({ !$0.isEmpty })
            .joined(separator: "\n"),
           !joined.isEmpty {
            return [joined]
        }
        return []
    }

    private static func loadImageData(for item: RecipeEntry) -> Data? {
        if let base64 = item.imageBase64,
           let data = Data(base64Encoded: base64) {
            return data
        }

        guard let imageId = item.imageId?.trimmingCharacters(in: .whitespacesAndNewlines),
              !imageId.isEmpty else {
            return nil
        }

        let extensions = ["jpg", "jpeg", "png", "heic", "webp"]
        for ext in extensions {
            if let url = Bundle.main.url(
                forResource: imageId,
                withExtension: ext,
                subdirectory: "RecipeImages"
            ), let data = try? Data(contentsOf: url) {
                return data
            }
            if let url = Bundle.main.url(forResource: imageId, withExtension: ext),
               let data = try? Data(contentsOf: url) {
                return data
            }
        }
        return nil
    }
}

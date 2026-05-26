import Foundation
import SwiftData

enum RecipeCatalogSeeder {
    private struct CatalogFile: Decodable {
        var version: Int?
        var recipes: [RecipeItem]
    }

    struct RecipeItem: Decodable {
        struct IngredientItem: Decodable {
            var catalogKey: String
            var quantity: Double
            var unit: String
        }

        var id: String?
        var name: String
        var servings: Int?
        var imageId: String?
        var imageBase64: String?
        var steps: [String]?
        var ingredients: [IngredientItem]?
    }

    @MainActor
    static func syncCatalog(in context: ModelContext) {
        guard let url = Bundle.main.url(forResource: "recipes-catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(CatalogFile.self, from: data) else {
            return
        }

        var existingById: [String: Recipe] = [:]
        let descriptor = FetchDescriptor<Recipe>()
        if let all = try? context.fetch(descriptor) {
            for recipe in all {
                if let id = recipe.catalogRecipeId {
                    existingById[id] = recipe
                }
            }
        }

        for item in catalog.recipes {
            let catalogId = resolvedCatalogId(for: item)
            guard !catalogId.isEmpty else { continue }

            if let recipe = existingById[catalogId] {
                apply(item: item, catalogId: catalogId, to: recipe, in: context)
            } else if let recipe = makeRecipe(from: item, catalogId: catalogId, in: context) {
                context.insert(recipe)
                existingById[catalogId] = recipe
            }
        }

        LocalPersistence.save(context)
    }

    @MainActor
    private static func apply(item: RecipeItem, catalogId: String, to recipe: Recipe, in context: ModelContext) {
        let name = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        recipe.catalogRecipeId = catalogId
        recipe.name = name
        recipe.servings = max(item.servings ?? 1, 1)
        recipe.imageData = loadImageData(for: item)
        recipe.steps = item.steps ?? []
        replaceIngredients(for: recipe, from: item, in: context)
        recipe.recalculateNutrition()
    }

    @MainActor
    private static func makeRecipe(from item: RecipeItem, catalogId: String, in context: ModelContext) -> Recipe? {
        let name = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }

        let recipe = Recipe(
            name: name,
            catalogRecipeId: catalogId,
            servings: max(item.servings ?? 1, 1),
            imageData: loadImageData(for: item),
            steps: item.steps ?? []
        )
        replaceIngredients(for: recipe, from: item, in: context)
        recipe.recalculateNutrition()
        return recipe
    }

    @MainActor
    private static func replaceIngredients(for recipe: Recipe, from item: RecipeItem, in context: ModelContext) {
        for ingredient in recipe.ingredients {
            context.delete(ingredient)
        }
        recipe.ingredients = []

        for entry in item.ingredients ?? [] {
            guard let product = FoodCatalogSeeder.product(forKey: entry.catalogKey, in: context) else {
                continue
            }
            let unit = MeasurementUnit(rawValue: entry.unit) ?? .gram
            let ingredient = Ingredient(
                name: product.displayName,
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

    private static func resolvedCatalogId(for item: RecipeItem) -> String {
        let raw = (item.id ?? item.name)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return raw
    }

    private static func loadImageData(for item: RecipeItem) -> Data? {
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

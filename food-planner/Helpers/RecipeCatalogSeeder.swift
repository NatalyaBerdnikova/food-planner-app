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
        var imageId: String?
        var imageBase64: String?
        var steps: [String]?
        var ingredients: [IngredientItem]?
    }

    @MainActor
    static func seedIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<Recipe>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        guard let url = Bundle.main.url(forResource: "recipes-catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(CatalogFile.self, from: data) else {
            return
        }

        for item in catalog.recipes {
            guard let recipe = makeRecipe(from: item, in: context) else { continue }
            context.insert(recipe)
        }

        LocalPersistence.save(context)
    }

    @MainActor
    private static func makeRecipe(from item: RecipeItem, in context: ModelContext) -> Recipe? {
        let name = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }

        let recipe = Recipe(
            name: name,
            imageData: loadImageData(for: item),
            steps: item.steps ?? []
        )

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

        recipe.recalculateNutrition()
        return recipe
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

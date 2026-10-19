import Foundation
import SwiftData

enum RecipeDiscoveryService {
    static func recipeOfTheDay(from recipes: [Recipe], on date: Date = .now) -> Recipe? {
        let visible = RecipeCollections.visible(recipes)
        let catalog = visible.filter(\.isCatalogRecipe)
        guard !catalog.isEmpty else {
            return visible
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                .first
        }

        let dayIndex = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        let sorted = catalog.sorted { lhs, rhs in
            let left = lhs.catalogRecipeId ?? lhs.name
            let right = rhs.catalogRecipeId ?? rhs.name
            return left < right
        }
        return sorted[dayIndex % sorted.count]
    }

    static func randomRecipe(from recipes: [Recipe], excluding excludedID: PersistentIdentifier? = nil) -> Recipe? {
        let visible = RecipeCollections.visible(recipes)
        let pool = visible.filter { recipe in
            guard let excludedID else { return true }
            return recipe.persistentModelID != excludedID
        }
        return pool.randomElement() ?? visible.randomElement()
    }
}

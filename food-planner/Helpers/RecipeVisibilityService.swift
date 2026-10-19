import Foundation
import SwiftData

enum RecipeVisibilityService {
    @MainActor
    static func hiddenCatalogRecipeIds(in context: ModelContext) -> Set<String> {
        Set(AppSettingsService.settings(in: context).hiddenCatalogRecipeIds)
    }

    @MainActor
    static func hideCatalogRecipe(_ recipe: Recipe, in context: ModelContext) {
        guard !recipe.isDeleted else { return }
        guard let catalogId = recipe.catalogRecipeId, !catalogId.isEmpty else { return }

        let settings = AppSettingsService.settings(in: context)
        var hidden = Set(settings.hiddenCatalogRecipeIds)
        hidden.insert(catalogId)
        settings.hiddenCatalogRecipeIds = hidden.sorted()

        if let key = RecipeFavoritesService.favoriteKey(for: recipe) {
            var favorites = Set(settings.favoriteCatalogRecipeIds)
            if favorites.remove(key) != nil {
                settings.favoriteCatalogRecipeIds = favorites.sorted()
            }
        }

        deleteMeals(of: recipe, in: context)
        context.delete(recipe)
        LocalPersistence.save(context)
    }

    @MainActor
    static func deleteUserRecipe(_ recipe: Recipe, in context: ModelContext) {
        guard !recipe.isDeleted else { return }
        guard recipe.isUserCreated else { return }

        if let key = RecipeFavoritesService.favoriteKey(for: recipe) {
            let settings = AppSettingsService.settings(in: context)
            var favorites = Set(settings.favoriteCatalogRecipeIds)
            if favorites.remove(key) != nil {
                settings.favoriteCatalogRecipeIds = favorites.sorted()
            }
        }

        deleteMeals(of: recipe, in: context)
        context.delete(recipe)
        RecipeCatalogStore.persistUserRecipes(in: context)
    }

    @MainActor
    private static func deleteMeals(of recipe: Recipe, in context: ModelContext) {
        let meals = Array(recipe.meals)
        for meal in meals {
            meal.recipe = nil
            context.delete(meal)
        }
    }
}

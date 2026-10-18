import Foundation
import SwiftData

enum RecipeVisibilityService {
    @MainActor
    static func hiddenCatalogRecipeIds(in context: ModelContext) -> Set<String> {
        Set(AppSettingsService.settings(in: context).hiddenCatalogRecipeIds)
    }

    @MainActor
    static func hideCatalogRecipe(_ recipe: Recipe, in context: ModelContext) {
        guard let catalogId = recipe.catalogRecipeId else { return }

        let settings = AppSettingsService.settings(in: context)
        var hidden = Set(settings.hiddenCatalogRecipeIds)
        hidden.insert(catalogId)
        settings.hiddenCatalogRecipeIds = hidden.sorted()

        RecipeFavoritesService.setFavorite(recipe, favorite: false, in: context)
        deleteMeals(of: recipe, in: context)
        context.delete(recipe)
        LocalPersistence.save(context)
    }

    @MainActor
    static func deleteUserRecipe(_ recipe: Recipe, in context: ModelContext) {
        guard recipe.isUserCreated else { return }

        RecipeFavoritesService.setFavorite(recipe, favorite: false, in: context)
        deleteMeals(of: recipe, in: context)
        context.delete(recipe)
        RecipeCatalogStore.persistUserRecipes(in: context)
    }

    @MainActor
    private static func deleteMeals(of recipe: Recipe, in context: ModelContext) {
        for meal in Array(recipe.meals) {
            context.delete(meal)
        }
    }
}

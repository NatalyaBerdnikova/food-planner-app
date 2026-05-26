import Foundation
import SwiftData

enum RecipeFavoritesService {
    @MainActor
    static func favoriteIds(in context: ModelContext) -> Set<String> {
        Set(AppSettingsService.settings(in: context).favoriteCatalogRecipeIds)
    }

    @MainActor
    static func isFavorite(_ recipe: Recipe, in context: ModelContext) -> Bool {
        guard let id = recipe.catalogRecipeId else { return false }
        return favoriteIds(in: context).contains(id)
    }

    @MainActor
    static func setFavorite(_ recipe: Recipe, favorite: Bool, in context: ModelContext) {
        guard let id = recipe.catalogRecipeId else { return }
        let settings = AppSettingsService.settings(in: context)
        var ids = Set(settings.favoriteCatalogRecipeIds)
        if favorite {
            ids.insert(id)
        } else {
            ids.remove(id)
        }
        settings.favoriteCatalogRecipeIds = ids.sorted()
        LocalPersistence.save(context)
    }
}

enum RecipeCollections {
    static func catalogRecipes(from recipes: [Recipe]) -> [Recipe] {
        recipes.filter(\.isCatalogRecipe)
    }

    static func libraryRecipes(from recipes: [Recipe], favoriteIds: Set<String>) -> [Recipe] {
        recipes.filter { recipe in
            if recipe.isUserCreated { return true }
            guard let id = recipe.catalogRecipeId else { return false }
            return favoriteIds.contains(id)
        }
    }
}

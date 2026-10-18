import Foundation
import SwiftData

enum RecipeFavoritesService {
    @MainActor
    static func favoriteIds(in context: ModelContext) -> Set<String> {
        Set(AppSettingsService.settings(in: context).favoriteCatalogRecipeIds)
    }

    static func favoriteKey(for recipe: Recipe) -> String? {
        recipe.catalogRecipeId ?? recipe.userRecipeId
    }

    @MainActor
    static func isFavorite(_ recipe: Recipe, in context: ModelContext) -> Bool {
        guard let key = favoriteKey(for: recipe) else { return false }
        return favoriteIds(in: context).contains(key)
    }

    static func canFavorite(_ recipe: Recipe) -> Bool {
        favoriteKey(for: recipe) != nil
    }

    @MainActor
    static func setFavorite(_ recipe: Recipe, favorite: Bool, in context: ModelContext) {
        guard let key = favoriteKey(for: recipe) else { return }
        let settings = AppSettingsService.settings(in: context)
        var ids = Set(settings.favoriteCatalogRecipeIds)
        if favorite {
            ids.insert(key)
        } else {
            ids.remove(key)
        }
        settings.favoriteCatalogRecipeIds = ids.sorted()
        LocalPersistence.save(context)
    }

    static func favoriteRecipes(from recipes: [Recipe], favoriteIds: Set<String>) -> [Recipe] {
        guard !favoriteIds.isEmpty else { return [] }
        return recipes
            .filter { recipe in
                guard let key = favoriteKey(for: recipe) else { return false }
                return favoriteIds.contains(key)
            }
            .sorted {
                $0.localizedName.localizedCaseInsensitiveCompare($1.localizedName) == .orderedAscending
            }
    }
}

enum RecipeCollections {
    static func catalogRecipes(from recipes: [Recipe]) -> [Recipe] {
        recipes.filter(\.isCatalogRecipe)
    }

    static func userRecipes(from recipes: [Recipe]) -> [Recipe] {
        recipes
            .filter(\.isUserCreated)
            .sorted { $0.localizedName.localizedCaseInsensitiveCompare($1.localizedName) == .orderedAscending }
    }

    static func sortedCatalogRecipes(from recipes: [Recipe]) -> [Recipe] {
        recipes
            .filter(\.isCatalogRecipe)
            .sorted { $0.localizedName.localizedCaseInsensitiveCompare($1.localizedName) == .orderedAscending }
    }

    static func libraryRecipes(from recipes: [Recipe]) -> [Recipe] {
        userRecipes(from: recipes) + sortedCatalogRecipes(from: recipes)
    }
}

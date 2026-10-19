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
        let wasFavorite = ids.contains(key)

        if favorite, !wasFavorite {
            ids.insert(key)
            adjustCommunityLikeCount(for: recipe, delta: 1)
        } else if !favorite, wasFavorite {
            ids.remove(key)
            adjustCommunityLikeCount(for: recipe, delta: -1)
        } else {
            return
        }

        settings.favoriteCatalogRecipeIds = ids.sorted()
        LocalPersistence.save(context)
    }

    private static func adjustCommunityLikeCount(for recipe: Recipe, delta: Int) {
        guard !recipe.isUserCreated else { return }
        recipe.communityLikeCount = max(0, min(recipe.communityLikeCount + delta, 100))
    }

    static func favoriteRecipes(from recipes: [Recipe], favoriteIds: Set<String>) -> [Recipe] {
        guard !favoriteIds.isEmpty else { return [] }
        return RecipeCollections.visible(recipes)
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
    static func visible(_ recipes: [Recipe]) -> [Recipe] {
        recipes.filter(\.isVisibleInApp)
    }

    static func catalogRecipes(from recipes: [Recipe]) -> [Recipe] {
        visible(recipes).filter(\.isCatalogRecipe)
    }

    static func userRecipes(from recipes: [Recipe]) -> [Recipe] {
        visible(recipes)
            .filter(\.isUserCreated)
            .sorted { $0.localizedName.localizedCaseInsensitiveCompare($1.localizedName) == .orderedAscending }
    }

    static func sortedCatalogRecipes(from recipes: [Recipe]) -> [Recipe] {
        visible(recipes)
            .filter(\.isCatalogRecipe)
            .sorted { $0.localizedName.localizedCaseInsensitiveCompare($1.localizedName) == .orderedAscending }
    }

    static func libraryRecipes(from recipes: [Recipe]) -> [Recipe] {
        userRecipes(from: recipes) + sortedCatalogRecipes(from: recipes)
    }
}

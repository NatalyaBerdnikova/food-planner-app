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

    /// Returns `true` when the recipe newly becomes a favorite.
    @MainActor
    @discardableResult
    static func setFavorite(_ recipe: Recipe, favorite: Bool, in context: ModelContext) -> Bool {
        guard let key = favoriteKey(for: recipe) else { return false }
        let settings = AppSettingsService.settings(in: context)
        var ids = Set(settings.favoriteCatalogRecipeIds)
        let wasFavorite = ids.contains(key)
        var becameFavorite = false

        if favorite, !wasFavorite {
            ids.insert(key)
            adjustCommunityLikeCount(for: recipe, delta: 1)
            becameFavorite = true
        } else if !favorite, wasFavorite {
            ids.remove(key)
            adjustCommunityLikeCount(for: recipe, delta: -1)
        } else {
            return false
        }

        settings.favoriteCatalogRecipeIds = ids.sorted()
        LocalPersistence.save(context)
        return becameFavorite
    }

    private static func adjustCommunityLikeCount(for recipe: Recipe, delta: Int) {
        guard !recipe.isUserCreated else { return }
        recipe.communityLikeCount = max(0, min(recipe.communityLikeCount + delta, 100))
    }

    static func favoriteRecipes(from recipes: [Recipe], favoriteIds: Set<String>) -> [Recipe] {
        guard !favoriteIds.isEmpty else { return [] }
        return RecipeCollections.libraryRecipes(from: recipes)
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
        deduplicatedCatalogRecipes(from: visible(recipes))
    }

    static func userRecipes(from recipes: [Recipe]) -> [Recipe] {
        visible(recipes)
            .filter(\.isUserCreated)
            .sorted { $0.localizedName.localizedCaseInsensitiveCompare($1.localizedName) == .orderedAscending }
    }

    static func sortedCatalogRecipes(from recipes: [Recipe]) -> [Recipe] {
        catalogRecipes(from: recipes)
            .sorted { $0.localizedName.localizedCaseInsensitiveCompare($1.localizedName) == .orderedAscending }
    }

    static func libraryRecipes(from recipes: [Recipe]) -> [Recipe] {
        userRecipes(from: recipes) + sortedCatalogRecipes(from: recipes)
    }

    /// Plan generation clones share `catalogRecipeId` with the seed recipe; keep one library row.
    static func deduplicatedCatalogRecipes(from recipes: [Recipe]) -> [Recipe] {
        var bestByCatalogId: [String: Recipe] = [:]
        for recipe in recipes where recipe.isCatalogRecipe {
            guard let catalogId = recipe.catalogRecipeId else { continue }
            if let existing = bestByCatalogId[catalogId] {
                if prefersCatalogInstance(recipe, over: existing) {
                    bestByCatalogId[catalogId] = recipe
                }
            } else {
                bestByCatalogId[catalogId] = recipe
            }
        }
        return Array(bestByCatalogId.values)
    }

    private static func prefersCatalogInstance(_ recipe: Recipe, over existing: Recipe) -> Bool {
        let recipeIsCanonical = recipe.meals.isEmpty
        let existingIsCanonical = existing.meals.isEmpty
        if recipeIsCanonical != existingIsCanonical {
            return recipeIsCanonical
        }
        return false
    }
}

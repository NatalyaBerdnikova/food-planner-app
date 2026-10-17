import Foundation
import SwiftData

@Model
final class Recipe {
    /// Стабильный id из системного `recipes-catalog.json`; `nil` — не каталоговый рецепт.
    var catalogRecipeId: String?
    /// Стабильный id пользовательского рецепта из `recipes-user.json`.
    var userRecipeId: String?

    var name: String
    /// На сколько порций указаны количества ингредиентов (минимум 1).
    var servings: Int = 1
    @Attribute(.externalStorage) var imageData: Data?
    var sourceURL: String?
    var steps: [String]
    @Attribute(.externalStorage) var stepsRichTextData: Data?

    /// Время готовки в минутах; `0` — неизвестно.
    var cookTimeMinutes: Int = 0
    /// Социальный счётчик лайков (обновляется при заходе в приложение).
    var communityLikeCount: Int = 0
    /// Личный рейтинг пользователя; `0` — нет оценки, `1...5` — оценка.
    var userRating: Int = 0

    /// Калории на 100 г
    var caloriesPer100g: Double
    /// Белки на 100 г
    var proteinPer100g: Double
    /// Жиры на 100 г
    var fatPer100g: Double
    /// Углеводы на 100 г
    var carbsPer100g: Double

    @Relationship(deleteRule: .cascade, inverse: \Ingredient.recipe)
    var ingredients: [Ingredient]

    @Relationship(inverse: \Meal.recipe)
    var meals: [Meal]

    var isCatalogRecipe: Bool { catalogRecipeId != nil }
    var isUserCreated: Bool { catalogRecipeId == nil }

    var hasCookTime: Bool { cookTimeMinutes > 0 }

    init(
        name: String,
        catalogRecipeId: String? = nil,
        userRecipeId: String? = nil,
        servings: Int = 1,
        imageData: Data? = nil,
        sourceURL: String? = nil,
        steps: [String] = [],
        stepsRichTextData: Data? = nil,
        cookTimeMinutes: Int = 0,
        communityLikeCount: Int = 0,
        userRating: Int = 0,
        caloriesPer100g: Double = 0,
        proteinPer100g: Double = 0,
        fatPer100g: Double = 0,
        carbsPer100g: Double = 0,
        ingredients: [Ingredient] = []
    ) {
        self.catalogRecipeId = catalogRecipeId
        self.userRecipeId = userRecipeId
        self.name = name
        self.servings = max(servings, 1)
        self.imageData = imageData
        self.sourceURL = sourceURL
        self.steps = steps
        self.stepsRichTextData = stepsRichTextData
        self.cookTimeMinutes = max(cookTimeMinutes, 0)
        self.communityLikeCount = max(0, min(communityLikeCount, 100))
        self.userRating = max(0, min(userRating, 5))
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.fatPer100g = fatPer100g
        self.carbsPer100g = carbsPer100g
        self.ingredients = ingredients
        self.meals = []
    }

    func setUserRating(_ rating: Int) {
        userRating = max(0, min(rating, 5))
    }
}

import Foundation
import SwiftData

@Model
final class Recipe {
    /// Стабильный id из `recipes-catalog.json`; `nil` — рецепт создан пользователем.
    var catalogRecipeId: String?

    var name: String
    /// На сколько порций указаны количества ингредиентов (минимум 1).
    var servings: Int = 1
    @Attribute(.externalStorage) var imageData: Data?
    var sourceURL: String?
    var steps: [String]
    @Attribute(.externalStorage) var stepsRichTextData: Data?

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

    init(
        name: String,
        catalogRecipeId: String? = nil,
        servings: Int = 1,
        imageData: Data? = nil,
        sourceURL: String? = nil,
        steps: [String] = [],
        stepsRichTextData: Data? = nil,
        caloriesPer100g: Double = 0,
        proteinPer100g: Double = 0,
        fatPer100g: Double = 0,
        carbsPer100g: Double = 0,
        ingredients: [Ingredient] = []
    ) {
        self.catalogRecipeId = catalogRecipeId
        self.name = name
        self.servings = max(servings, 1)
        self.imageData = imageData
        self.sourceURL = sourceURL
        self.steps = steps
        self.stepsRichTextData = stepsRichTextData
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.fatPer100g = fatPer100g
        self.carbsPer100g = carbsPer100g
        self.ingredients = ingredients
        self.meals = []
    }
}

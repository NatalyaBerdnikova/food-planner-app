import Foundation
import SwiftData

@Model
final class Recipe {
    var name: String
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

    init(
        name: String,
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
        self.name = name
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

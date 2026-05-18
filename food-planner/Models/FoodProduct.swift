import Foundation
import SwiftData

@Model
final class FoodProduct {
    @Attribute(.unique) var catalogKey: String
    var category: IngredientCategory
    /// Масса одной штуки в граммах (для unit == .piece).
    var defaultPieceWeightGrams: Double

    var caloriesPer100g: Double
    var proteinPer100g: Double
    var fatPer100g: Double
    var carbsPer100g: Double

    var fiberPer100g: Double
    var sugarPer100g: Double
    var saturatedFatPer100g: Double
    var sodiumPer100g: Double
    var potassiumPer100g: Double
    var calciumPer100g: Double
    var ironPer100g: Double
    var magnesiumPer100g: Double
    var zincPer100g: Double
    var vitaminCPer100g: Double
    var vitaminDPer100g: Double
    var vitaminB12Per100g: Double
    var folatePer100g: Double

    @Relationship(inverse: \Ingredient.foodProduct)
    var ingredients: [Ingredient]

    init(
        catalogKey: String,
        category: IngredientCategory,
        defaultPieceWeightGrams: Double = 100,
        caloriesPer100g: Double,
        proteinPer100g: Double,
        fatPer100g: Double,
        carbsPer100g: Double,
        fiberPer100g: Double = 0,
        sugarPer100g: Double = 0,
        saturatedFatPer100g: Double = 0,
        sodiumPer100g: Double = 0,
        potassiumPer100g: Double = 0,
        calciumPer100g: Double = 0,
        ironPer100g: Double = 0,
        magnesiumPer100g: Double = 0,
        zincPer100g: Double = 0,
        vitaminCPer100g: Double = 0,
        vitaminDPer100g: Double = 0,
        vitaminB12Per100g: Double = 0,
        folatePer100g: Double = 0
    ) {
        self.catalogKey = catalogKey
        self.category = category
        self.defaultPieceWeightGrams = defaultPieceWeightGrams
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.fatPer100g = fatPer100g
        self.carbsPer100g = carbsPer100g
        self.fiberPer100g = fiberPer100g
        self.sugarPer100g = sugarPer100g
        self.saturatedFatPer100g = saturatedFatPer100g
        self.sodiumPer100g = sodiumPer100g
        self.potassiumPer100g = potassiumPer100g
        self.calciumPer100g = calciumPer100g
        self.ironPer100g = ironPer100g
        self.magnesiumPer100g = magnesiumPer100g
        self.zincPer100g = zincPer100g
        self.vitaminCPer100g = vitaminCPer100g
        self.vitaminDPer100g = vitaminDPer100g
        self.vitaminB12Per100g = vitaminB12Per100g
        self.folatePer100g = folatePer100g
        self.ingredients = []
    }

    var nutrientsPer100g: NutrientTotals {
        NutrientTotals(
            calories: caloriesPer100g,
            protein: proteinPer100g,
            fat: fatPer100g,
            carbs: carbsPer100g,
            fiber: fiberPer100g,
            sugar: sugarPer100g,
            saturatedFat: saturatedFatPer100g,
            sodium: sodiumPer100g,
            potassium: potassiumPer100g,
            calcium: calciumPer100g,
            iron: ironPer100g,
            magnesium: magnesiumPer100g,
            zinc: zincPer100g,
            vitaminC: vitaminCPer100g,
            vitaminD: vitaminDPer100g,
            vitaminB12: vitaminB12Per100g,
            folate: folatePer100g
        )
    }

    var localizationKey: String { "product.\(catalogKey)" }
}

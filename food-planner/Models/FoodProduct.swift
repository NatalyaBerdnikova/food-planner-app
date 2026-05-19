import Foundation
import SwiftData

@Model
final class FoodProduct {
    @Attribute(.unique) var catalogKey: String
    var category: IngredientCategory
    var defaultPieceWeightGrams: Double

    var caloriesPer100g: Double
    var proteinPer100g: Double
    var fatPer100g: Double
    var carbsPer100g: Double

    var fiberPer100g: Double
    var vitaminD3Per100g: Double
    var calciumPer100g: Double
    var magnesiumPer100g: Double
    var zincPer100g: Double
    var vitaminKPer100g: Double
    var vitaminCPer100g: Double
    var vitaminEPer100g: Double
    var vitaminAPer100g: Double
    var vitaminB6Per100g: Double
    var vitaminB9Per100g: Double
    var vitaminB12Per100g: Double
    var seleniumPer100g: Double
    var chromiumPer100g: Double
    var ironPer100g: Double
    var potassiumPer100g: Double
    var iodinePer100g: Double

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
        vitaminD3Per100g: Double = 0,
        calciumPer100g: Double = 0,
        magnesiumPer100g: Double = 0,
        zincPer100g: Double = 0,
        vitaminKPer100g: Double = 0,
        vitaminCPer100g: Double = 0,
        vitaminEPer100g: Double = 0,
        vitaminAPer100g: Double = 0,
        vitaminB6Per100g: Double = 0,
        vitaminB9Per100g: Double = 0,
        vitaminB12Per100g: Double = 0,
        seleniumPer100g: Double = 0,
        chromiumPer100g: Double = 0,
        ironPer100g: Double = 0,
        potassiumPer100g: Double = 0,
        iodinePer100g: Double = 0
    ) {
        self.catalogKey = catalogKey
        self.category = category
        self.defaultPieceWeightGrams = defaultPieceWeightGrams
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.fatPer100g = fatPer100g
        self.carbsPer100g = carbsPer100g
        self.fiberPer100g = fiberPer100g
        self.vitaminD3Per100g = vitaminD3Per100g
        self.calciumPer100g = calciumPer100g
        self.magnesiumPer100g = magnesiumPer100g
        self.zincPer100g = zincPer100g
        self.vitaminKPer100g = vitaminKPer100g
        self.vitaminCPer100g = vitaminCPer100g
        self.vitaminEPer100g = vitaminEPer100g
        self.vitaminAPer100g = vitaminAPer100g
        self.vitaminB6Per100g = vitaminB6Per100g
        self.vitaminB9Per100g = vitaminB9Per100g
        self.vitaminB12Per100g = vitaminB12Per100g
        self.seleniumPer100g = seleniumPer100g
        self.chromiumPer100g = chromiumPer100g
        self.ironPer100g = ironPer100g
        self.potassiumPer100g = potassiumPer100g
        self.iodinePer100g = iodinePer100g
        self.ingredients = []
    }

    var nutrientsPer100g: NutrientTotals {
        NutrientTotals(
            calories: caloriesPer100g,
            protein: proteinPer100g,
            fat: fatPer100g,
            carbs: carbsPer100g,
            fiber: fiberPer100g,
            vitaminD3: vitaminD3Per100g,
            calcium: calciumPer100g,
            magnesium: magnesiumPer100g,
            zinc: zincPer100g,
            vitaminK: vitaminKPer100g,
            vitaminC: vitaminCPer100g,
            vitaminE: vitaminEPer100g,
            vitaminA: vitaminAPer100g,
            vitaminB6: vitaminB6Per100g,
            vitaminB9: vitaminB9Per100g,
            vitaminB12: vitaminB12Per100g,
            selenium: seleniumPer100g,
            chromium: chromiumPer100g,
            iron: ironPer100g,
            potassium: potassiumPer100g,
            iodine: iodinePer100g
        )
    }

    var localizationKey: String { "product.\(catalogKey)" }

    var displayName: String {
        String(localized: String.LocalizationValue(localizationKey))
    }
}

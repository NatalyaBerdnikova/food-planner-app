import Foundation
import SwiftData

@Model
final class Ingredient {
    var name: String
    var quantity: Double
    var unit: MeasurementUnit
    var category: IngredientCategory

    var recipe: Recipe?
    var foodProduct: FoodProduct?

    init(
        name: String,
        quantity: Double,
        unit: MeasurementUnit,
        category: IngredientCategory = .other,
        recipe: Recipe? = nil,
        foodProduct: FoodProduct? = nil
    ) {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.recipe = recipe
        self.foodProduct = foodProduct
        if let product = foodProduct {
            self.category = product.category
        }
    }
}

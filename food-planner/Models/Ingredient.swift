import Foundation
import SwiftData

@Model
final class Ingredient {
    var name: String
    var quantity: Double
    var unit: MeasurementUnit
    var category: IngredientCategory

    var recipe: Recipe?

    init(
        name: String,
        quantity: Double,
        unit: MeasurementUnit,
        category: IngredientCategory = .other,
        recipe: Recipe? = nil
    ) {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.recipe = recipe
    }
}

import Foundation
import SwiftData

@Model
final class ShoppingItem {
    var name: String
    var quantity: Double
    var unit: MeasurementUnit
    var isPurchased: Bool
    var category: IngredientCategory
    /// Позиция добавлена вручную (не только из плана питания).
    var isManual: Bool

    var weekPlan: WeekPlan?

    init(
        name: String,
        quantity: Double,
        unit: MeasurementUnit,
        isPurchased: Bool = false,
        category: IngredientCategory = .other,
        isManual: Bool = false,
        weekPlan: WeekPlan? = nil
    ) {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.isPurchased = isPurchased
        self.category = category
        self.isManual = isManual
        self.weekPlan = weekPlan
    }

    var displayName: String {
        L10n.resolvedProductName(name)
    }
}

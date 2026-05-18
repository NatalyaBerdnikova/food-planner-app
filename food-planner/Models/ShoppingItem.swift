import Foundation
import SwiftData

@Model
final class ShoppingItem {
    var name: String
    var quantity: Double
    var unit: MeasurementUnit
    var isPurchased: Bool

    var weekPlan: WeekPlan?

    init(
        name: String,
        quantity: Double,
        unit: MeasurementUnit,
        isPurchased: Bool = false,
        weekPlan: WeekPlan? = nil
    ) {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.isPurchased = isPurchased
        self.weekPlan = weekPlan
    }
}

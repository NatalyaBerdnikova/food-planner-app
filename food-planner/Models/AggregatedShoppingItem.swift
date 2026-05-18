import Foundation

/// Строка агрегированного списка покупок (не сохраняется в SwiftData).
struct AggregatedShoppingItem: Identifiable, Hashable {
    let id: String
    let name: String
    let quantity: Double
    let unit: MeasurementUnit
    let category: IngredientCategory

    var formattedQuantity: String {
        L10n.amount(quantity: quantity, unit: unit)
    }
}

import Foundation

/// Строка агрегированного списка покупок (не сохраняется в SwiftData).
struct AggregatedShoppingItem: Identifiable, Hashable {
    let id: String
    let name: String
    let quantity: Double
    let unit: MeasurementUnit
    let category: IngredientCategory

    var formattedQuantity: String {
        let value = quantity.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", quantity)
            : String(format: "%.1f", quantity)
        return "\(value) \(unit.displayName)"
    }
}

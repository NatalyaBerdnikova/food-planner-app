import Foundation

enum L10n {
    static func kcalPer100g(_ calories: Int) -> String {
        String(localized: "nutrition.kcalPer100g \(calories)")
    }

    static func kcalShort(_ calories: Int) -> String {
        String(localized: "nutrition.kcalShort \(calories)")
    }

    static func recipeTotalCalories(_ calories: Int) -> String {
        String(localized: "nutrition.recipeTotal \(calories)")
    }

    static func recipeCaloriesPerServing(_ calories: Int) -> String {
        String(localized: "nutrition.recipePerServing \(calories)")
    }

    static func recipeWeight(_ grams: Int) -> String {
        String(localized: "nutrition.recipeWeight \(grams)")
    }

    static func recipeWeightPerServing(_ grams: Int) -> String {
        String(localized: "nutrition.recipeWeightPerServing \(grams)")
    }

    private static let productsTable = "Products"

    static func productName(catalogKey: String) -> String {
        String(
            localized: String.LocalizationValue("product.\(catalogKey)"),
            table: productsTable
        )
    }

    static func resolvedProductName(_ name: String) -> String {
        if name.hasPrefix("product.") {
            return String(localized: String.LocalizationValue(name), table: productsTable)
        }
        if looksLikeCatalogKey(name) {
            return productName(catalogKey: name)
        }
        return name
    }

    private static func looksLikeCatalogKey(_ name: String) -> Bool {
        guard !name.isEmpty, !name.contains(" ") else { return false }
        return name.allSatisfy { $0.isLetter || $0 == "_" || $0.isNumber }
    }

    static func amount(quantity: Double, unit: MeasurementUnit) -> String {
        let value = formatNumber(quantity)
        return String(localized: "format.amount \(value) \(unit.localizedName)")
    }

    static func shoppingShareLine(
        purchased: Bool,
        name: String,
        quantity: Double,
        unit: MeasurementUnit
    ) -> String {
        let mark = purchased
            ? String(localized: "shopping.share.purchasedMark")
            : String(localized: "shopping.share.pendingMark")
        let qty = formatNumber(quantity)
        let resolvedName = resolvedProductName(name)
        return String(localized: "shopping.share.line \(mark) \(resolvedName) \(qty) \(unit.localizedName)")
    }

    private static func formatNumber(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}

import Foundation

enum L10n {
    static var locale: Locale {
        switch resolvedAppLanguage {
        case .system:
            return .current
        case .english:
            return Locale(identifier: "en")
        case .russian:
            return Locale(identifier: "ru")
        }
    }

    private static var resolvedAppLanguage: AppLanguage {
        let stored = UserDefaults.standard.string(forKey: AppLanguage.storageKey)
            ?? AppLanguage.system.rawValue
        return AppLanguage(rawValue: stored) ?? .system
    }

    static var currentLanguageCode: String {
        switch resolvedAppLanguage {
        case .system:
            return Locale.current.language.languageCode?.identifier ?? "en"
        case .english:
            return "en"
        case .russian:
            return "ru"
        }
    }

    static func string(_ key: String.LocalizationValue) -> String {
        String(localized: key, locale: locale)
    }

    static func kcalPer100g(_ calories: Int) -> String {
        string("nutrition.kcalPer100g \(calories)")
    }

    static func kcalShort(_ calories: Int) -> String {
        string("nutrition.kcalShort \(calories)")
    }

    static func recipeTotalCalories(_ calories: Int) -> String {
        string("nutrition.recipeTotal \(calories)")
    }

    static func recipeCaloriesPerServing(_ calories: Int) -> String {
        string("nutrition.recipePerServing \(calories)")
    }

    static func recipeWeight(_ grams: Int) -> String {
        string("nutrition.recipeWeight \(grams)")
    }

    static func recipeWeightPerServing(_ grams: Int) -> String {
        string("nutrition.recipeWeightPerServing \(grams)")
    }

    static func productName(catalogKey: String) -> String {
        if let catalogName = FoodCatalogLocalization.name(
            for: catalogKey,
            languageCode: currentLanguageCode
        ) {
            return catalogName
        }
        return catalogKey.replacingOccurrences(of: "_", with: " ").capitalized
    }

    static func resolvedProductName(_ name: String) -> String {
        if name.hasPrefix("product.") {
            return productName(catalogKey: String(name.dropFirst("product.".count)))
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
        return string("format.amount \(value) \(unit.localizedName)")
    }

    static func shoppingShareLine(
        purchased: Bool,
        name: String,
        quantity: Double,
        unit: MeasurementUnit
    ) -> String {
        let mark = purchased
            ? string("shopping.share.purchasedMark")
            : string("shopping.share.pendingMark")
        let qty = formatNumber(quantity)
        let resolvedName = resolvedProductName(name)
        return string("shopping.share.line \(mark) \(resolvedName) \(qty) \(unit.localizedName)")
    }

    private static func formatNumber(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}

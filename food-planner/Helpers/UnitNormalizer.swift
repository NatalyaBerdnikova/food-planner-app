import Foundation

enum UnitNormalizer {
    static func normalize(_ raw: String) -> MeasurementUnit {
        let key = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: ".", with: "")

        if let exact = MeasurementUnit(rawValue: key) {
            return exact
        }

        switch key {
        case "g", "gr", "gram", "grams", "г", "гр", "грамм", "грамма", "граммы":
            return .gram
        case "kg", "kilogram", "kilograms", "кг", "килограмм", "килограмма", "килограммы":
            return .kilogram
        case "ml", "milliliter", "milliliters", "мл", "миллилитр", "миллилитра", "миллилитры":
            return .milliliter
        case "l", "liter", "liters", "litre", "litres", "л", "литр", "литра", "литры":
            return .liter
        case "pc", "pcs", "piece", "pieces", "шт", "штука", "штуки", "штук",
             "stick", "sticks", "стик", "стика", "стиков", "стики",
             "зубчик", "зубчика", "зубчиков", "зубчики",
             "пучок", "пучка", "пучков", "пучки",
             "стебель", "стебля", "стеблей",
             "по вкусу", "щепотка", "щепотку", "немного":
            return .piece
        case "tbsp", "tablespoon", "tablespoons", "стл", "ст.л", "ст.л.", "ст л",
             "столовая ложка", "столовые ложки", "столовых ложек":
            return .tablespoon
        case "tsp", "teaspoon", "teaspoons", "чл", "ч.л", "ч.л.", "ч л",
             "чайная ложка", "чайные ложки", "чайных ложек":
            return .teaspoon
        default:
            return .gram
        }
    }
}

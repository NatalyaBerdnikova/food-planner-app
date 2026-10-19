import Foundation

enum IngredientAmountParser {
    struct ParsedAmount {
        var name: String
        var quantity: Double?
        var unit: MeasurementUnit?
    }

    static func normalize(_ ingredient: ParsedIngredient) -> ParsedIngredient {
        let parsed = extract(from: ingredient.rawName)
        let cleanedName = parsed.name.isEmpty ? ingredient.rawName : parsed.name

        let quantity: Double
        let unit: MeasurementUnit

        if let extractedQuantity = parsed.quantity, extractedQuantity > 0 {
            quantity = extractedQuantity
            unit = parsed.unit ?? UnitNormalizer.normalize(ingredient.unit)
        } else if ingredient.quantity > 0 {
            quantity = ingredient.quantity
            unit = UnitNormalizer.normalize(ingredient.unit)
        } else {
            quantity = 1
            unit = UnitNormalizer.normalize(ingredient.unit)
        }

        return ParsedIngredient(
            catalogKey: ingredient.catalogKey,
            rawName: cleanedName,
            quantity: quantity,
            unit: unit.rawValue
        )
    }

    static func extract(from rawName: String) -> ParsedAmount {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ParsedAmount(name: rawName, quantity: nil, unit: nil)
        }

        if looksLikeInstruction(trimmed) {
            return ParsedAmount(name: trimmed, quantity: nil, unit: nil)
        }

        if let match = matchTrailingAmount(in: trimmed) {
            return match
        }

        return ParsedAmount(name: trimmed, quantity: nil, unit: nil)
    }

    private static func looksLikeInstruction(_ text: String) -> Bool {
        let lowered = text.lowercased()
        let markers = [
            "примерно в", "раза больше", "раз больше", "кбжу",
            "указала", "указал", "смотреть", "см.", "рилл",
        ]
        return markers.contains { lowered.contains($0) } || text.count > 60
    }

    private static func matchTrailingAmount(in text: String) -> ParsedAmount? {
        let pattern = #"(?i)^(.+?)\s+(\d+(?:[.,]\d+)?)\s*([a-zа-яё.%]+(?:\s*[a-zа-яё.]+)?)?\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let nameRange = Range(match.range(at: 1), in: text),
              let quantityRange = Range(match.range(at: 2), in: text) else {
            return nil
        }

        let name = String(text[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count >= 2 else { return nil }

        let quantityRaw = text[quantityRange].replacingOccurrences(of: ",", with: ".")
        guard let quantity = Double(quantityRaw), quantity > 0 else { return nil }

        var unit: MeasurementUnit?
        if match.range(at: 3).location != NSNotFound,
           let unitRange = Range(match.range(at: 3), in: text) {
            let unitRaw = String(text[unitRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !unitRaw.isEmpty {
                if isKnownUnit(unitRaw) {
                    unit = UnitNormalizer.normalize(unitRaw)
                } else if unitRaw.allSatisfy(\.isNumber) {
                    return nil
                } else {
                    return nil
                }
            }
        }

        if unit == nil {
            let loweredName = name.lowercased()
            if loweredName.contains("вода") || loweredName.contains("молоко") || loweredName.contains("сок") {
                unit = .milliliter
            } else {
                unit = .gram
            }
        }

        return ParsedAmount(name: name, quantity: quantity, unit: unit)
    }

    private static func isKnownUnit(_ raw: String) -> Bool {
        let key = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: " ", with: "")

        let known = [
            "g", "gr", "gram", "grams", "г", "гр", "грамм", "грамма", "граммы",
            "kg", "kilogram", "kilograms", "кг", "килограмм", "килограмма", "килограммы",
            "ml", "milliliter", "milliliters", "мл", "миллилитр", "миллилитра", "миллилитры",
            "l", "liter", "liters", "litre", "litres", "л", "литр", "литра", "литры",
            "pc", "pcs", "piece", "pieces", "шт", "штука", "штуки", "штук",
            "stick", "sticks", "стик", "стика", "стиков", "стики",
            "tbsp", "tablespoon", "tablespoons", "стл", "столоваяложка", "столовыеложки",
            "tsp", "teaspoon", "teaspoons", "чл", "чайнаяложка", "чайныеложки",
        ]
        return known.contains(key)
    }
}

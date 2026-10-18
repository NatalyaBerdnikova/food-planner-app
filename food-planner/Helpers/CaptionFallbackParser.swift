import Foundation

enum CaptionFallbackParser {
    private static let ingredientHeaders = ["ингредиенты", "ingredients", "состав"]
    private static let stepHeaders = [
        "приготовление", "способ приготовления", "инструкция", "instructions", "directions",
    ]

    static func parse(caption: String, transcript: String) -> ParsedRecipe? {
        let captionText = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        let transcriptText = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !captionText.isEmpty || !transcriptText.isEmpty else { return nil }

        if !captionText.isEmpty, let recipe = parseCaption(captionText) {
            if recipe.steps.isEmpty, !transcriptText.isEmpty {
                return ParsedRecipe(
                    name: recipe.name,
                    servings: recipe.servings,
                    cookTimeMinutes: recipe.cookTimeMinutes,
                    steps: stepsFromTranscript(transcriptText),
                    ingredients: recipe.ingredients
                )
            }
            return recipe
        }

        if !transcriptText.isEmpty {
            let lines = nonEmptyLines(in: transcriptText)
            guard let title = lines.first else { return nil }
            return ParsedRecipe(
                name: stripLeadingMarkers(title),
                servings: nil,
                cookTimeMinutes: nil,
                steps: Array(lines.dropFirst()),
                ingredients: []
            )
        }

        return nil
    }

    private static func parseCaption(_ caption: String) -> ParsedRecipe? {
        let lines = nonEmptyLines(in: caption)
        guard !lines.isEmpty else { return nil }

        let ingredientStart = indexOfSectionHeader(in: lines, headers: ingredientHeaders)
        let stepStart = indexOfSectionHeader(in: lines, headers: stepHeaders)

        let name = recipeName(from: lines, ingredientStart: ingredientStart, stepStart: stepStart)
        guard !name.isEmpty else { return nil }

        var ingredients: [ParsedIngredient] = []
        if let ingredientStart {
            let ingredientEnd = stepStart ?? lines.count
            let ingredientLines = lines[(ingredientStart + 1)..<ingredientEnd]
            ingredients = ingredientLines.compactMap(parseIngredientLine)
        }

        var steps: [String] = []
        if let stepStart {
            steps = lines[(stepStart + 1)...].map(stripLeadingMarkers).filter { !$0.isEmpty }
        }

        return ParsedRecipe(
            name: name,
            servings: nil,
            cookTimeMinutes: nil,
            steps: steps,
            ingredients: ingredients
        )
    }

    private static func stepsFromTranscript(_ transcript: String) -> [String] {
        nonEmptyLines(in: transcript).map(stripLeadingMarkers).filter { !$0.isEmpty }
    }

    private static func recipeName(
        from lines: [String],
        ingredientStart: Int?,
        stepStart: Int?
    ) -> String {
        let boundary = [ingredientStart, stepStart, lines.count].compactMap { $0 }.min() ?? lines.count
        guard boundary > 0 else { return "" }
        return stripLeadingMarkers(lines[0])
    }

    private static func nonEmptyLines(in text: String) -> [String] {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private static func indexOfSectionHeader(in lines: [String], headers: [String]) -> Int? {
        lines.firstIndex { line in
            let normalized = line
                .lowercased()
                .trimmingCharacters(in: .punctuationCharacters.union(.whitespaces))
            return headers.contains { normalized == $0 || normalized.hasPrefix("\($0):") }
        }
    }

    private static func parseIngredientLine(_ line: String) -> ParsedIngredient? {
        let cleaned = stripLeadingMarkers(line)
        guard !cleaned.isEmpty else { return nil }

        let separators = [" — ", " – ", " - ", "—", "–", "-"]
        var namePart = cleaned
        var amountPart = ""

        for separator in separators {
            if let range = cleaned.range(of: separator) {
                namePart = String(cleaned[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                amountPart = String(cleaned[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                break
            }
        }

        guard !namePart.isEmpty else { return nil }

        let (quantity, unit) = parseAmount(amountPart)
        return ParsedIngredient(
            catalogKey: nil,
            rawName: namePart,
            quantity: quantity,
            unit: unit.rawValue
        )
    }

    private static func parseAmount(_ text: String) -> (Double, MeasurementUnit) {
        let lowered = text.lowercased()
        if lowered.contains("на глаз") || lowered.contains("по вкусу") {
            return (0, .gram)
        }

        let unit = detectUnit(in: lowered)
        if let quantity = firstNumber(in: text), quantity > 0 {
            return (quantity, unit)
        }

        return (1, unit)
    }

    private static func detectUnit(in text: String) -> MeasurementUnit {
        if text.contains("шт") { return .piece }
        if text.contains("ст.л") { return .tablespoon }
        if text.contains("ч.л") { return .teaspoon }
        if text.contains("кг") { return .kilogram }
        if text.contains("мл") { return .milliliter }
        if text.contains(" л") || text.hasSuffix("л") { return .liter }
        if text.contains("г") { return .gram }
        return .gram
    }

    private static func firstNumber(in text: String) -> Double? {
        let pattern = #"(\d+(?:[.,]\d+)?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        let raw = text[range].replacingOccurrences(of: ",", with: ".")
        return Double(raw)
    }

    private static func stripLeadingMarkers(_ line: String) -> String {
        var result = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = #"^[\d\p{Emoji_Presentation}\p{Extended_Pictographic}\s.)]+"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: result, range: NSRange(result.startIndex..., in: result)),
           let range = Range(match.range, in: result) {
            result = String(result[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        return result
    }
}

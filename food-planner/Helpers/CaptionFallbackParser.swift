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
                    stepsIntro: nil,
                    steps: stepsFromTranscript(transcriptText),
                    ingredients: recipe.ingredients
                )
            }
            return recipe
        }

        if !transcriptText.isEmpty {
            let lines = nonEmptyLines(in: transcriptText)
            guard let title = lines.first else { return nil }
            let name = stripHashtagsAndMentions(stripLeadingMarkers(title))
            guard !name.isEmpty else { return nil }
            return ParsedRecipe(
                name: name,
                servings: nil,
                cookTimeMinutes: nil,
                stepsIntro: nil,
                steps: Array(lines.dropFirst())
                    .map(stripLeadingMarkers)
                    .map(stripHashtagsAndMentions)
                    .filter { !$0.isEmpty },
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
            steps = lines[(stepStart + 1)...]
                .map(stripLeadingMarkers)
                .map(stripHashtagsAndMentions)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }

        return ParsedRecipe(
            name: stripHashtagsAndMentions(name),
            servings: nil,
            cookTimeMinutes: nil,
            stepsIntro: nil,
            steps: steps
                .map(stripHashtagsAndMentions)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty },
            ingredients: ingredients.map { item in
                ParsedIngredient(
                    catalogKey: item.catalogKey,
                    rawName: stripHashtagsAndMentions(item.rawName),
                    quantity: item.quantity,
                    unit: item.unit
                )
            }.filter { !$0.rawName.isEmpty }
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
        let cleaned = stripIngredientDecorations(line)
        guard !cleaned.isEmpty else { return nil }
        if isHashtagOnlyLine(cleaned) {
            return nil
        }

        let lowered = cleaned.lowercased()
        if lowered.hasPrefix("для ") || lowered.hasPrefix("for the ") {
            return nil
        }

        let separators = [" — ", " – ", " - ", "—", "–"]
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

        if amountPart.isEmpty {
            let extracted = IngredientAmountParser.extract(from: namePart)
            let quantity = extracted.quantity ?? 1
            let unit = extracted.unit ?? .gram
            let rawName = stripHashtagsAndMentions(
                extracted.name.isEmpty ? namePart : extracted.name
            )
            guard !rawName.isEmpty else { return nil }
            return ParsedIngredient(
                catalogKey: nil,
                rawName: rawName,
                quantity: quantity > 0 ? quantity : 1,
                unit: unit.rawValue
            )
        }

        let (quantity, unit) = parseAmount(amountPart)
        return ParsedIngredient(
            catalogKey: nil,
            rawName: stripHashtagsAndMentions(namePart),
            quantity: quantity > 0 ? quantity : 1,
            unit: unit.rawValue
        )
    }

    private static func parseAmount(_ text: String) -> (Double, MeasurementUnit) {
        let lowered = text.lowercased()
        if lowered.contains("на глаз") || lowered.contains("по вкусу") || lowered.contains("to taste") {
            return (1, .piece)
        }

        let unit = detectUnit(in: lowered)
        if let quantity = firstNumber(in: text), quantity > 0 {
            return (quantity, unit)
        }

        return (1, unit)
    }

    private static func detectUnit(in text: String) -> MeasurementUnit {
        let compact = text.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: " ", with: "")
        if compact.contains("шт") { return .piece }
        if compact.contains("стл") || text.contains("ст.л") { return .tablespoon }
        if compact.contains("чл") || text.contains("ч.л") { return .teaspoon }
        if compact.contains("кг") { return .kilogram }
        if compact.contains("мл") { return .milliliter }
        if text.contains(" л") || compact == "л" || text.hasSuffix(" л") { return .liter }
        if compact.contains("г") || compact.contains("гр") { return .gram }
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
        let patterns = [
            #"^[\p{Emoji_Presentation}\p{Extended_Pictographic}\s]+"#,
            #"^\d+[\.\)\:]\s+"#,
            #"^[•\-–—]\s+"#,
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: result, range: NSRange(result.startIndex..., in: result)),
               let range = Range(match.range, in: result) {
                result = String(result[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            }
        }
        return result
    }

    private static func stripIngredientDecorations(_ line: String) -> String {
        var result = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let patterns = [
            #"^[\p{Emoji_Presentation}\p{Extended_Pictographic}\s]+"#,
            #"^[•\-–—]\s+"#,
            #"^\d+[\.\)\:]\s+(?=\D)"#,
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: result, range: NSRange(result.startIndex..., in: result)),
               let range = Range(match.range, in: result) {
                result = String(result[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            }
        }
        return result
    }

    private static func stripHashtagsAndMentions(_ text: String) -> String {
        text
            .replacingOccurrences(
                of: #"#[\p{L}\p{N}_]+"#,
                with: "",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #"@[\p{L}\p{N._]+"#,
                with: "",
                options: .regularExpression
            )
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isHashtagOnlyLine(_ text: String) -> Bool {
        stripHashtagsAndMentions(text).isEmpty
    }
}

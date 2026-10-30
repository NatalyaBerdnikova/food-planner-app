import Foundation
import SwiftData

struct UnresolvedIngredient: Identifiable {
    let id = UUID()
    var rawName: String
    var suggestedQuantity: Double
    var suggestedUnit: MeasurementUnit
}

enum UnresolvedIngredientsShare {
    static func text(
        recipeName: String?,
        items: [UnresolvedIngredient],
        sourceURL: String? = nil
    ) -> String {
        let header = String(localized: "import.unresolved.shareHeader")
        let trimmedName = recipeName?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let title: String
        if let trimmedName, !trimmedName.isEmpty {
            title = "\(header): \(trimmedName)"
        } else {
            title = header
        }
        var parts: [String] = [title]
        parts.append(
            contentsOf: items.map { item in
                let amount = L10n.amount(quantity: item.suggestedQuantity, unit: item.suggestedUnit)
                return "• \(item.rawName) — \(amount)"
            }
        )
        if let sourceURL = sourceURL?.trimmingCharacters(in: .whitespacesAndNewlines),
           !sourceURL.isEmpty {
            parts.append("")
            parts.append(sourceURL)
        }
        return parts.joined(separator: "\n")
    }
}

struct ImportedRecipeDraft: Identifiable {
    let id = UUID()
    var name: String
    var sourceURL: String?
    var sourceDescription: String? = nil
    var servings: Int?
    var cookTimeMinutes: Int? = nil
    var steps: [String]
    var stepsIntro: String? = nil
    var stepsRichTextData: Data? = nil
    var imageData: Data?
    var ingredients: [DraftIngredient]
    var unresolvedIngredients: [UnresolvedIngredient]
}

enum RecipeImportError: LocalizedError {
    case unreadableFile
    case invalidFormat
    case networkFailure
    case instagramUnavailable
    case transcriptionFailed
    case parsingFailed
    case apiQuotaExceeded
    case apiUnauthorized

    var analyticsCode: String {
        switch self {
        case .unreadableFile: "unreadable_file"
        case .invalidFormat: "invalid_format"
        case .networkFailure: "network_failure"
        case .instagramUnavailable: "instagram_unavailable"
        case .transcriptionFailed: "transcription_failed"
        case .parsingFailed: "parsing_failed"
        case .apiQuotaExceeded: "api_quota_exceeded"
        case .apiUnauthorized: "api_unauthorized"
        }
    }

    var errorDescription: String? {
        switch self {
        case .unreadableFile: String(localized: "import.error.unreadable")
        case .invalidFormat: String(localized: "import.error.invalid")
        case .networkFailure: String(localized: "import.error.network")
        case .instagramUnavailable: String(localized: "import.error.instagram")
        case .transcriptionFailed: String(localized: "import.error.transcription")
        case .parsingFailed: String(localized: "import.error.parsing")
        case .apiQuotaExceeded: String(localized: "import.error.api.quota")
        case .apiUnauthorized: String(localized: "import.error.api.auth")
        }
    }
}

enum RecipeImportService {
    struct RecipeJSON: Decodable {
        struct IngredientJSON: Decodable {
            var catalogKey: String
            var quantity: Double
            var unit: String
        }

        var name: String
        var sourceURL: String?
        var sourceDescription: String?
        var steps: [String]?
        var ingredients: [IngredientJSON]?
    }

    @MainActor
    static func importFromFile(url: URL, in context: ModelContext) throws -> ImportedRecipeDraft {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess { url.stopAccessingSecurityScopedResource() }
        }

        let data = try Data(contentsOf: url)
        return try parse(data: data, fileExtension: url.pathExtension, in: context)
    }

    @MainActor
    static func parse(data: Data, fileExtension: String, in context: ModelContext) throws -> ImportedRecipeDraft {
        if fileExtension.lowercased() == "json" || (try? JSONSerialization.jsonObject(with: data)) != nil {
            return try parseJSON(data: data, in: context)
        }
        return try parsePlainText(data: data, in: context)
    }

    @MainActor
    private static func parseJSON(data: Data, in context: ModelContext) throws -> ImportedRecipeDraft {
        let decoded = try JSONDecoder().decode(RecipeJSON.self, from: data)
        guard !decoded.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw RecipeImportError.invalidFormat
        }

        let ingredients = try (decoded.ingredients ?? []).map { item in
            try draftIngredient(from: item, in: context)
        }

        let description = decoded.sourceDescription?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return ImportedRecipeDraft(
            name: decoded.name.trimmingCharacters(in: .whitespaces),
            sourceURL: decoded.sourceURL,
            sourceDescription: (description?.isEmpty == false) ? description : nil,
            servings: nil,
            steps: decoded.steps ?? [],
            ingredients: ingredients,
            unresolvedIngredients: []
        )
    }

    @MainActor
    private static func parsePlainText(data: Data, in context: ModelContext) throws -> ImportedRecipeDraft {
        guard let text = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            throw RecipeImportError.unreadableFile
        }

        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard let title = lines.first else { throw RecipeImportError.invalidFormat }

        return ImportedRecipeDraft(
            name: title,
            steps: Array(lines.dropFirst()),
            ingredients: [],
            unresolvedIngredients: []
        )
    }

    @MainActor
    private static func draftIngredient(
        from json: RecipeJSON.IngredientJSON,
        in context: ModelContext
    ) throws -> DraftIngredient {
        guard let product = FoodCatalogSeeder.product(forKey: json.catalogKey, in: context) else {
            throw RecipeImportError.invalidFormat
        }
        let unit = MeasurementUnit(rawValue: json.unit) ?? .gram
        return DraftIngredient(product: product, quantity: json.quantity, unit: unit)
    }
}

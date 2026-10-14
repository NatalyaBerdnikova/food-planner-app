import Foundation
import SwiftData

struct ParsedIngredient {
    var catalogKey: String?
    var rawName: String
    var quantity: Double
    var unit: String
}

enum IngredientCatalogMatcher {
    struct MatchResult {
        var resolved: [DraftIngredient]
        var unresolved: [UnresolvedIngredient]
    }

    @MainActor
    static func match(
        _ ingredients: [ParsedIngredient],
        in context: ModelContext
    ) -> MatchResult {
        var resolved: [DraftIngredient] = []
        var unresolved: [UnresolvedIngredient] = []

        for item in ingredients {
            let unit = UnitNormalizer.normalize(item.unit)
            let quantity = item.quantity > 0 ? item.quantity : 1

            if let key = item.catalogKey?.trimmingCharacters(in: .whitespacesAndNewlines),
               !key.isEmpty,
               let product = FoodCatalogSeeder.product(forKey: key, in: context) {
                resolved.append(DraftIngredient(product: product, quantity: quantity, unit: unit))
                continue
            }

            if let key = fuzzyMatchCatalogKey(for: item.rawName),
               let product = FoodCatalogSeeder.product(forKey: key, in: context) {
                resolved.append(DraftIngredient(product: product, quantity: quantity, unit: unit))
                continue
            }

            unresolved.append(
                UnresolvedIngredient(
                    rawName: item.rawName,
                    suggestedQuantity: quantity,
                    suggestedUnit: unit
                )
            )
        }

        return MatchResult(resolved: resolved, unresolved: unresolved)
    }

    private static func fuzzyMatchCatalogKey(for rawName: String) -> String? {
        let query = normalizeForMatch(rawName)
        guard !query.isEmpty else { return nil }

        var bestKey: String?
        var bestScore = 0

        for key in IngredientCatalogPrompt.allCatalogKeys() {
            let candidates = [
                FoodCatalogLocalization.name(for: key, languageCode: "ru"),
                FoodCatalogLocalization.name(for: key, languageCode: "en"),
                key.replacingOccurrences(of: "_", with: " "),
            ].compactMap { $0 }

            for candidate in candidates {
                let normalized = normalizeForMatch(candidate)
                let score = matchScore(query: query, candidate: normalized)
                if score > bestScore {
                    bestScore = score
                    bestKey = key
                }
            }
        }

        return bestScore >= 70 ? bestKey : nil
    }

    private static func normalizeForMatch(_ text: String) -> String {
        text
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "_", with: " ")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func matchScore(query: String, candidate: String) -> Int {
        if query == candidate { return 100 }
        if candidate.contains(query) || query.contains(candidate) { return 85 }
        let queryTokens = Set(query.split(separator: " ").map(String.init))
        let candidateTokens = Set(candidate.split(separator: " ").map(String.init))
        guard !queryTokens.isEmpty, !candidateTokens.isEmpty else { return 0 }
        let overlap = queryTokens.intersection(candidateTokens).count
        let union = queryTokens.union(candidateTokens).count
        return Int((Double(overlap) / Double(union)) * 100)
    }
}

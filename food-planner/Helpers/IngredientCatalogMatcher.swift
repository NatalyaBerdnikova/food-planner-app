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
        let index = CatalogMatchIndex.build()

        for rawItem in ingredients {
            let item = IngredientAmountParser.normalize(rawItem)
            let unit = UnitNormalizer.normalize(item.unit)
            let quantity = item.quantity > 0 ? item.quantity : 1

            if let key = item.catalogKey?.trimmingCharacters(in: .whitespacesAndNewlines),
               !key.isEmpty,
               let product = FoodCatalogSeeder.product(forKey: key, in: context) {
                resolved.append(DraftIngredient(product: product, quantity: quantity, unit: unit))
                continue
            }

            if let key = fuzzyMatchCatalogKey(for: item.rawName, index: index),
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

    private static func fuzzyMatchCatalogKey(for rawName: String, index: CatalogMatchIndex) -> String? {
        let query = normalizeForMatch(rawName)
        guard !query.isEmpty else { return nil }

        let queryStem = IngredientNameStemmer.stem(query)
        var bestKey: String?
        var bestScore = 0
        var bestRank = Int.max

        for entry in index.entries {
            for candidate in entry.candidates {
                let score = matchScore(
                    query: query,
                    queryStem: queryStem,
                    candidate: candidate.normalized,
                    candidateStem: candidate.stemmed
                )
                let rank = candidate.stemmed.split(separator: " ").count * 1000
                    + candidate.normalized.count
                if score > bestScore || (score == bestScore && rank < bestRank) {
                    bestScore = score
                    bestRank = rank
                    bestKey = entry.key
                }
            }
        }

        return bestScore >= 70 ? bestKey : nil
    }

    private static func normalizeForMatch(_ text: String) -> String {
        text
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "ё", with: "е")
            .replacingOccurrences(of: "_", with: " ")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func matchScore(
        query: String,
        queryStem: String,
        candidate: String,
        candidateStem: String
    ) -> Int {
        if query == candidate || (!queryStem.isEmpty && queryStem == candidateStem) {
            return 100
        }

        let queryTokenList = tokenList(in: queryStem.isEmpty ? query : queryStem)
        let candidateTokenList = tokenList(in: candidateStem.isEmpty ? candidate : candidateStem)
        guard !queryTokenList.isEmpty, !candidateTokenList.isEmpty else { return 0 }

        let queryTokens = Set(queryTokenList)
        let candidateTokens = Set(candidateTokenList)

        if queryTokenList.count == 1 {
            let single = queryTokenList[0]
            if let index = candidateTokenList.firstIndex(of: single) {
                return singleTokenScore(
                    index: index,
                    candidateTokenList: candidateTokenList
                )
            }
            return 0
        }

        let overlap = queryTokens.intersection(candidateTokens)
        if overlap.isEmpty {
            var softOverlap = 0
            for qToken in queryTokens where qToken.count >= 4 {
                if candidateTokens.contains(where: {
                    $0.hasPrefix(qToken) || qToken.hasPrefix($0)
                }) {
                    softOverlap += 1
                }
            }
            guard softOverlap > 0 else { return 0 }
            return Int((Double(softOverlap) / Double(queryTokens.count)) * 88)
        }

        if overlap == queryTokens {
            return 92
        }

        let union = queryTokens.union(candidateTokens).count
        return Int((Double(overlap.count) / Double(union)) * 100)
    }

    private static func tokenList(in text: String) -> [String] {
        text.split(separator: " ").map(String.init).filter { !$0.isEmpty }
    }

    private static let derivedProductMarkers: Set<String> = [
        "мук", "масл", "сок", "паст", "круп", "бумаг", "сироп",
        "хлоп", "хлопя", "каш", "хлеб", "бульон", "экстракт",
    ]

    private static func singleTokenScore(index: Int, candidateTokenList: [String]) -> Int {
        if candidateTokenList.count == 1 { return 100 }

        let hasDerivedMarker = candidateTokenList.enumerated().contains { offset, token in
            offset != index && derivedProductMarkers.contains(token)
        }

        if index == 0 {
            return hasDerivedMarker ? 78 : 96
        }
        if index == candidateTokenList.count - 1 {
            return hasDerivedMarker ? 82 : 90
        }
        return 65
    }

    private struct CatalogMatchIndex {
        struct Candidate {
            var normalized: String
            var stemmed: String
        }

        struct Entry {
            var key: String
            var candidates: [Candidate]
        }

        var entries: [Entry]

        static func build() -> CatalogMatchIndex {
            let languageCode = L10n.currentLanguageCode
            let preferredCodes = languageCode.hasPrefix("ru") ? ["ru", "en"] : ["en", "ru"]
            var entries: [Entry] = []

            for key in IngredientCatalogPrompt.allCatalogKeys() {
                var texts: [String] = [
                    key.replacingOccurrences(of: "_", with: " "),
                ]
                for code in preferredCodes {
                    if let name = FoodCatalogLocalization.name(for: key, languageCode: code) {
                        texts.append(name)
                    }
                }

                let candidates = Array(
                    Set(texts.map { normalizeForMatch($0) }.filter { !$0.isEmpty })
                ).map { normalized in
                    Candidate(
                        normalized: normalized,
                        stemmed: IngredientNameStemmer.stem(normalized)
                    )
                }

                guard !candidates.isEmpty else { continue }
                entries.append(Entry(key: key, candidates: candidates))
            }

            return CatalogMatchIndex(entries: entries)
        }

        private static func normalizeForMatch(_ text: String) -> String {
            text
                .lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)
                .replacingOccurrences(of: "ё", with: "е")
                .replacingOccurrences(of: "_", with: " ")
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }
    }
}

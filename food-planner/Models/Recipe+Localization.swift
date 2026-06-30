import Foundation

extension Recipe {
    var localizedName: String {
        if let catalogRecipeId,
           let name = RecipeCatalogLocalization.name(
            for: catalogRecipeId,
            languageCode: L10n.currentLanguageCode
           ) {
            return name
        }
        return name
    }

    var localizedStepsText: String? {
        if isUserCreated {
            if let data = stepsRichTextData,
               let attributed = RecipeStepsStorage.attributedString(from: data),
               !attributed.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return attributed.string
            }
            let joined = steps
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
            return joined.isEmpty ? nil : joined
        }

        if let catalogRecipeId,
           let steps = RecipeCatalogLocalization.steps(
            for: catalogRecipeId,
            languageCode: L10n.currentLanguageCode
           ) {
            return steps
        }

        let joined = steps
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        return joined.isEmpty ? nil : joined
    }

    var hasLocalizedSteps: Bool {
        localizedStepsText != nil
    }

    func matchesSearch(_ query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }

        if localizedName.localizedCaseInsensitiveContains(trimmed) {
            return true
        }

        if let catalogRecipeId {
            return RecipeCatalogLocalization.matchesSearch(catalogRecipeId: catalogRecipeId, query: trimmed)
        }

        if let stepsText = localizedStepsText,
           stepsText.localizedCaseInsensitiveContains(trimmed) {
            return true
        }

        return false
    }
}

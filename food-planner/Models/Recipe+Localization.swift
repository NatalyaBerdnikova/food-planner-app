import Foundation
import UIKit

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

    var localizedStepsAttributed: NSAttributedString? {
        if isUserCreated {
            if let data = stepsRichTextData,
               let attributed = RecipeStepsStorage.attributedString(from: data),
               !attributed.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return attributed
            }
            let joined = steps
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
            guard !joined.isEmpty else { return nil }
            return NSAttributedString(string: joined, attributes: RecipeStepsStorage.defaultBodyAttributes())
        }

        if let catalogRecipeId,
           let steps = RecipeCatalogLocalization.steps(
            for: catalogRecipeId,
            languageCode: L10n.currentLanguageCode
           ),
           !steps.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return NSAttributedString(string: steps, attributes: RecipeStepsStorage.defaultBodyAttributes())
        }

        let joined = steps
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        guard !joined.isEmpty else { return nil }
        return NSAttributedString(string: joined, attributes: RecipeStepsStorage.defaultBodyAttributes())
    }

    var localizedStepsText: String? {
        localizedStepsAttributed?.string
    }

    var hasLocalizedSteps: Bool {
        localizedStepsAttributed != nil
    }

    func matchesSearch(_ query: String) -> Bool {
        matchesNameSearch(query)
    }

    func matchesNameSearch(_ query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }

        if localizedName.localizedCaseInsensitiveContains(trimmed)
            || name.localizedCaseInsensitiveContains(trimmed) {
            return true
        }

        if let catalogRecipeId {
            return RecipeCatalogLocalization.matchesNameSearch(
                catalogRecipeId: catalogRecipeId,
                query: trimmed
            )
        }

        return false
    }

    func matchesIngredientSearch(_ query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        for ingredient in ingredients {
            if ingredient.displayName.localizedCaseInsensitiveContains(trimmed)
                || ingredient.name.localizedCaseInsensitiveContains(trimmed) {
                return true
            }
            if let catalogKey = ingredient.foodProduct?.catalogKey,
               FoodCatalogLocalization.matchesSearch(catalogKey: catalogKey, query: trimmed) {
                return true
            }
        }
        return false
    }
}

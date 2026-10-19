import SwiftUI

struct MicronutrientDetailSheet: View {
    let totals: NutrientTotals
    var micronutrientFocus: [MicronutrientKind] = []
    private let showsEmptyState: Bool
    private let footerText: LocalizedStringResource?

    @Environment(\.dismiss) private var dismiss

    init(
        totals: NutrientTotals,
        micronutrientFocus: [MicronutrientKind] = [],
        showsEmptyState: Bool = false,
        footerText: LocalizedStringResource? = "nutrition.microDailyReference.day"
    ) {
        self.totals = totals
        self.micronutrientFocus = micronutrientFocus
        self.showsEmptyState = showsEmptyState
        self.footerText = footerText
    }

    init(recipe: Recipe, micronutrientFocus: [MicronutrientKind] = []) {
        let nutrition = NutritionCalculator.recipeNutrition(recipe)
        let servings = max(Double(recipe.servings), 1)
        self.totals = nutrition.total.scaled(by: 1 / servings)
        self.micronutrientFocus = micronutrientFocus
        self.showsEmptyState = nutrition.totalWeightGrams <= 0
        self.footerText = "nutrition.microDailyReference"
    }

    private var focusedKinds: [MicronutrientKind] {
        micronutrientFocus.filter { MicronutrientKind.allCases.contains($0) }
    }

    private var otherKinds: [MicronutrientKind] {
        let focused = Set(focusedKinds)
        return MicronutrientKind.allCases.filter { !focused.contains($0) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if showsEmptyState {
                    ContentUnavailableView(
                        "nutrition.noIngredients",
                        systemImage: "leaf",
                        description: Text("nutrition.noIngredients.hint")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(focusedKinds) { kind in
                                row(for: kind)
                            }

                            if !focusedKinds.isEmpty, !otherKinds.isEmpty {
                                Divider()
                                    .padding(.vertical, 4)
                            }

                            ForEach(otherKinds) { kind in
                                row(for: kind)
                            }

                            if let footerText {
                                Text(footerText)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(AppTheme.contentPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .navigationTitle("nutrition.microTitle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") { dismiss() }
                }
            }
        }
    }

    private func row(for kind: MicronutrientKind) -> some View {
        MicronutrientProgressRow(
            kind: kind,
            actual: totals.value(for: kind)
        )
    }
}

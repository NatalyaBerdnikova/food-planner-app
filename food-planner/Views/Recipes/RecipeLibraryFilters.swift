import Foundation
import SwiftUI
import SwiftData

struct RecipeAdvancedFilters: Equatable {
    var maxCalories: Double = Self.caloriesUpperBound
    var maxCookTimeMinutes: Int = Self.cookTimeUpperBound
    var ingredientCatalogKeys: [String] = []
    var matchAnyIngredient: Bool = true

    static let caloriesUpperBound: Double = 1200
    static let cookTimeUpperBound: Int = 180

    var isCaloriesLimited: Bool {
        maxCalories < Self.caloriesUpperBound
    }

    var isCookTimeLimited: Bool {
        maxCookTimeMinutes < Self.cookTimeUpperBound
    }

    var hasIngredientFilter: Bool {
        !ingredientCatalogKeys.isEmpty
    }

    var isActive: Bool {
        isCaloriesLimited || isCookTimeLimited || hasIngredientFilter
    }

    mutating func reset() {
        self = RecipeAdvancedFilters()
    }

    func matches(_ recipe: Recipe) -> Bool {
        let nutrition = NutritionCalculator.nutritionPerServing(for: recipe)

        if isCaloriesLimited, nutrition.calories > maxCalories {
            return false
        }

        if isCookTimeLimited {
            if !recipe.hasCookTime || recipe.cookTimeMinutes > maxCookTimeMinutes {
                return false
            }
        }

        if hasIngredientFilter {
            let recipeKeys = Set(recipe.ingredients.compactMap(\.foodProduct?.catalogKey))
            let selected = Set(ingredientCatalogKeys)
            if matchAnyIngredient {
                if selected.isDisjoint(with: recipeKeys) {
                    return false
                }
            } else if !selected.isSubset(of: recipeKeys) {
                return false
            }
        }

        return true
    }
}

struct RecipeAdvancedFiltersSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FoodProduct.catalogKey) private var products: [FoodProduct]
    @Binding var filters: RecipeAdvancedFilters

    @State private var draft: RecipeAdvancedFilters

    init(filters: Binding<RecipeAdvancedFilters>) {
        _filters = filters
        _draft = State(initialValue: filters.wrappedValue)
    }

    private var selectedTags: [(key: String, name: String)] {
        draft.ingredientCatalogKeys.map { key in
            let name = products.first { $0.catalogKey == key }?.displayName
                ?? L10n.productName(catalogKey: key)
            return (key: key, name: name)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("recipeLibrary.filterCalories")
                            Spacer()
                            Text(caloriesLabel)
                                .foregroundStyle(.secondary)
                        }
                        Slider(
                            value: $draft.maxCalories,
                            in: 100...RecipeAdvancedFilters.caloriesUpperBound,
                            step: 50
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("recipeLibrary.filterCookTime")
                            Spacer()
                            Text(cookTimeLabel)
                                .foregroundStyle(.secondary)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(draft.maxCookTimeMinutes) },
                                set: { draft.maxCookTimeMinutes = Int($0) }
                            ),
                            in: 5...Double(RecipeAdvancedFilters.cookTimeUpperBound),
                            step: 5
                        )
                    }
                }

                Section {
                    ingredientTagEditor

                    Toggle(isOn: $draft.matchAnyIngredient) {
                        Text("recipeLibrary.matchAnyIngredient")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .disabled(draft.ingredientCatalogKeys.isEmpty)
                } header: {
                    Text("recipeLibrary.filterIngredients")
                } footer: {
                    Text(
                        draft.matchAnyIngredient
                            ? "recipeLibrary.matchAnyIngredient.footer"
                            : "recipeLibrary.matchAllIngredients.footer"
                    )
                }
            }
            .navigationTitle("recipeLibrary.advancedFilters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("recipeLibrary.resetFilters") {
                        draft.reset()
                    }
                    .disabled(!draft.isActive)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") {
                        filters = draft
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .appFormSheetPresentation()
    }

    private var ingredientTagEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !selectedTags.isEmpty {
                IngredientTagFlowLayout(spacing: 8) {
                    ForEach(selectedTags, id: \.key) { tag in
                        selectedIngredientChip(key: tag.key, name: tag.name)
                    }
                }
            }

            IngredientTagSearchField(
                excludedCatalogKeys: Set(draft.ingredientCatalogKeys)
            ) { product in
                guard !draft.ingredientCatalogKeys.contains(product.catalogKey) else { return }
                draft.ingredientCatalogKeys.append(product.catalogKey)
            }
        }
        .padding(.vertical, 4)
    }

    private func selectedIngredientChip(key: String, name: String) -> some View {
        Button {
            draft.ingredientCatalogKeys.removeAll { $0 == key }
        } label: {
            HStack(spacing: 6) {
                Text(name)
                    .lineLimit(1)
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .accessibilityHint(Text("recipeLibrary.removeIngredientTag"))
    }

    private var caloriesLabel: String {
        if draft.isCaloriesLimited {
            String(localized: "recipeLibrary.maxCalories \(Int(draft.maxCalories.rounded()))")
        } else {
            String(localized: "recipeLibrary.anyCalories")
        }
    }

    private var cookTimeLabel: String {
        if draft.isCookTimeLimited {
            String(localized: "recipeLibrary.maxCookTime \(draft.maxCookTimeMinutes)")
        } else {
            String(localized: "recipeLibrary.anyCookTime")
        }
    }
}

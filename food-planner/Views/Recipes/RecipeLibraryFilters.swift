import Foundation
import SwiftUI
import SwiftData

struct RecipeAdvancedFilters: Equatable {
    var maxCalories: Double = Self.caloriesUpperBound
    var maxCookTimeMinutes: Int = Self.cookTimeUpperBound
    var ingredientCatalogKeys: [String] = []

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
            for key in ingredientCatalogKeys where !recipeKeys.contains(key) {
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
    @State private var ingredientSearch = ""

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

    private var suggestedProducts: [FoodProduct] {
        let query = ingredientSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        let selected = Set(draft.ingredientCatalogKeys)
        return products
            .filter { !selected.contains($0.catalogKey) }
            .filter { FoodCatalogLocalization.matchesSearch(catalogKey: $0.catalogKey, query: query) }
            .prefix(12)
            .map { $0 }
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
                } header: {
                    Text("recipeLibrary.filterIngredients")
                }
            }
            .navigationTitle("recipeLibrary.advancedFilters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("recipeLibrary.resetFilters") {
                        draft.reset()
                        ingredientSearch = ""
                    }
                    .disabled(!draft.isActive && ingredientSearch.isEmpty)
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

            TextField(
                "recipeLibrary.filterIngredients.placeholder",
                text: $ingredientSearch
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .onSubmit(commitFirstSuggestionIfNeeded)

            if !suggestedProducts.isEmpty {
                IngredientTagFlowLayout(spacing: 8) {
                    ForEach(suggestedProducts, id: \.catalogKey) { product in
                        suggestionChip(product)
                    }
                }
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

    private func suggestionChip(_ product: FoodProduct) -> some View {
        Button {
            addIngredient(product)
        } label: {
            Text(product.displayName)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color(.tertiarySystemFill))
                .foregroundStyle(.primary)
                .clipShape(Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func addIngredient(_ product: FoodProduct) {
        guard !draft.ingredientCatalogKeys.contains(product.catalogKey) else { return }
        draft.ingredientCatalogKeys.append(product.catalogKey)
        ingredientSearch = ""
    }

    private func commitFirstSuggestionIfNeeded() {
        guard let first = suggestedProducts.first else { return }
        addIngredient(first)
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

private struct IngredientTagFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalWidth = max(totalWidth, currentX - spacing)
            totalHeight = currentY + rowHeight
        }

        return CGSize(
            width: proposal.width ?? totalWidth,
            height: totalHeight
        )
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX, currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(size)
            )
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

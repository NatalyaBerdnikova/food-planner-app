import SwiftUI
import SwiftData

struct IngredientTagSearchField: View {
    @Query(sort: \FoodProduct.catalogKey) private var products: [FoodProduct]

    var excludedCatalogKeys: Set<String> = []
    var placeholder: LocalizedStringKey = "recipeLibrary.filterIngredients.placeholder"
    var onSelect: (FoodProduct) -> Void

    @State private var searchText: String
    @FocusState private var isSearchFocused: Bool

    init(
        excludedCatalogKeys: Set<String> = [],
        placeholder: LocalizedStringKey = "recipeLibrary.filterIngredients.placeholder",
        initialSearchText: String = "",
        onSelect: @escaping (FoodProduct) -> Void
    ) {
        self.excludedCatalogKeys = excludedCatalogKeys
        self.placeholder = placeholder
        self.onSelect = onSelect
        _searchText = State(initialValue: initialSearchText)
    }

    private var suggestedProducts: [FoodProduct] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        return products
            .filter { !excludedCatalogKeys.contains($0.catalogKey) }
            .filter { FoodCatalogLocalization.matchesSearch(catalogKey: $0.catalogKey, query: query) }
            .prefix(12)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField(placeholder, text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($isSearchFocused)
                .onSubmit(commitFirstSuggestionIfNeeded)

            if !suggestedProducts.isEmpty {
                IngredientTagFlowLayout(spacing: 8) {
                    ForEach(suggestedProducts, id: \.catalogKey) { product in
                        suggestionChip(product)
                    }
                }
            }
        }
    }

    private func suggestionChip(_ product: FoodProduct) -> some View {
        Button {
            select(product)
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

    private func select(_ product: FoodProduct) {
        onSelect(product)
        searchText = ""
    }

    private func commitFirstSuggestionIfNeeded() {
        guard let first = suggestedProducts.first else { return }
        select(first)
    }
}

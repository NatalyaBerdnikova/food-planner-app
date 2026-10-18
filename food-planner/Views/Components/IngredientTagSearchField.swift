import SwiftUI
import SwiftData

struct IngredientTagSearchField: View {
    @Query(sort: \FoodProduct.catalogKey) private var products: [FoodProduct]

    var excludedCatalogKeys: Set<String> = []
    var placeholder: LocalizedStringKey = "recipeLibrary.filterIngredients.placeholder"
    var autofocus: Bool = false
    var onSearchActivity: (() -> Void)? = nil
    var onSelect: (FoodProduct) -> Void

    @State private var searchText: String
    @FocusState private var isSearchFocused: Bool

    init(
        excludedCatalogKeys: Set<String> = [],
        placeholder: LocalizedStringKey = "recipeLibrary.filterIngredients.placeholder",
        initialSearchText: String = "",
        autofocus: Bool = false,
        onSearchActivity: (() -> Void)? = nil,
        onSelect: @escaping (FoodProduct) -> Void
    ) {
        self.excludedCatalogKeys = excludedCatalogKeys
        self.placeholder = placeholder
        self.autofocus = autofocus
        self.onSearchActivity = onSearchActivity
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
                .task(id: autofocus) {
                    guard autofocus else { return }
                    try? await Task.sleep(for: .milliseconds(150))
                    isSearchFocused = true
                }

            if !suggestedProducts.isEmpty {
                IngredientTagFlowLayout(spacing: 8) {
                    ForEach(suggestedProducts, id: \.catalogKey) { product in
                        suggestionChip(product)
                    }
                }
            }
        }
        .onChange(of: searchText) { _, _ in
            notifySearchActivity()
        }
        .onChange(of: isSearchFocused) { _, focused in
            guard focused else { return }
            notifySearchActivity()
        }
        .onChange(of: suggestedProducts.count) { _, _ in
            notifySearchActivity()
        }
    }

    private func notifySearchActivity() {
        guard onSearchActivity != nil else { return }
        DispatchQueue.main.async {
            onSearchActivity?()
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

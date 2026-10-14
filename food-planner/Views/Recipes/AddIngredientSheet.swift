import SwiftUI
import SwiftData

struct DraftIngredient: Identifiable {
    let id = UUID()
    var product: FoodProduct
    var quantity: Double
    var unit: MeasurementUnit
}

struct AddIngredientSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FoodProduct.catalogKey) private var products: [FoodProduct]

    let onAdd: (DraftIngredient) -> Void

    @State private var selectedKey: String?
    @State private var gramsText = "100"
    @State private var searchText = ""
    @State private var quantityText: String
    @State private var unit: MeasurementUnit
    @State private var searchText: String

    init(
        initialSearchText: String = "",
        initialQuantity: Double = 100,
        initialUnit: MeasurementUnit = .gram,
        onAdd: @escaping (DraftIngredient) -> Void
    ) {
        self.onAdd = onAdd
        _quantityText = State(initialValue: Self.formatQuantity(initialQuantity))
        _unit = State(initialValue: initialUnit)
        _searchText = State(initialValue: initialSearchText)
    }

    private static func formatQuantity(_ value: Double) -> String {
        value == floor(value) ? String(Int(value)) : String(value)
    }

    private var selectedProduct: FoodProduct? {
        guard let key = selectedKey else { return nil }
        return products.first { $0.catalogKey == key }
    }

    private var filteredProducts: [FoodProduct] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return products }
        return products.filter { product in
            FoodCatalogLocalization.matchesSearch(catalogKey: product.catalogKey, query: query)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("addIngredient.product") {
                    if filteredProducts.isEmpty {
                        ContentUnavailableView(
                            "search.noResults",
                            systemImage: "magnifyingglass",
                            description: Text("search.noResults.hint")
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(filteredProducts, id: \.catalogKey) { product in
                            productRow(product)
                        }
                    }
                }

                Section("addIngredient.amount") {
                    HStack {
                        Text("addIngredient.grams")
                        Spacer()
                        TextField("0", text: $gramsText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 120)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "search.products")
            .navigationTitle("addIngredient.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.add") { addIngredient() }
                        .disabled(!canAdd)
                }
            }
        }
    }

    private func productRow(_ product: FoodProduct) -> some View {
        Button {
            selectedKey = product.catalogKey
        } label: {
            HStack {
                Text(product.displayName)
                    .foregroundStyle(.primary)
                Spacer()
                if selectedKey == product.catalogKey {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var canAdd: Bool {
        selectedProduct != nil && (parsedGrams() ?? 0) > 0
    }

    private func addIngredient() {
        guard let product = selectedProduct,
              let grams = parsedGrams(),
              grams > 0 else { return }

        onAdd(DraftIngredient(product: product, quantity: grams, unit: .gram))
        dismiss()
    }

    private func parsedGrams() -> Double? {
        Double(gramsText.replacingOccurrences(of: ",", with: "."))
    }
}

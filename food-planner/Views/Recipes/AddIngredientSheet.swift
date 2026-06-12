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
    @State private var quantityText = "100"
    @State private var gramsText = "100"
    @State private var unit: MeasurementUnit = .gram
    @State private var searchText = ""
    @State private var isSyncingAmountFields = false

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
                    TextField("addIngredient.quantity", text: $quantityText)
                        .keyboardType(.decimalPad)
                    Picker("addIngredient.unit", selection: $unit) {
                        ForEach(MeasurementUnit.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    TextField("addIngredient.grams", text: $gramsText)
                        .keyboardType(.decimalPad)
                }
            }
            .searchable(text: $searchText, prompt: "search.products")
            .onChange(of: quantityText) { _, _ in
                syncGramsFromQuantity()
            }
            .onChange(of: unit) { _, _ in
                syncGramsFromQuantity()
            }
            .onChange(of: gramsText) { _, _ in
                syncQuantityFromGrams()
            }
            .onChange(of: selectedKey) { _, _ in
                syncGramsFromQuantity()
            }
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
    }

    private var canAdd: Bool {
        guard selectedProduct != nil else { return false }
        return (parsedQuantity() ?? 0) > 0 || (parsedGrams() ?? 0) > 0
    }

    private func addIngredient() {
        guard let product = selectedProduct else { return }

        let quantity: Double
        if let parsed = parsedQuantity(), parsed > 0 {
            quantity = parsed
        } else if let grams = parsedGrams(), grams > 0 {
            quantity = UnitConverter.quantity(fromGrams: grams, unit: unit, product: product)
        } else {
            return
        }

        guard quantity > 0 else { return }

        onAdd(DraftIngredient(product: product, quantity: quantity, unit: unit))
        dismiss()
    }

    private func parsedQuantity() -> Double? {
        Double(quantityText.replacingOccurrences(of: ",", with: "."))
    }

    private func parsedGrams() -> Double? {
        Double(gramsText.replacingOccurrences(of: ",", with: "."))
    }

    private func syncGramsFromQuantity() {
        guard !isSyncingAmountFields,
              let product = selectedProduct,
              let quantity = parsedQuantity(),
              quantity > 0 else { return }

        isSyncingAmountFields = true
        let grams = UnitConverter.grams(quantity: quantity, unit: unit, product: product)
        gramsText = formatAmount(grams)
        isSyncingAmountFields = false
    }

    private func syncQuantityFromGrams() {
        guard !isSyncingAmountFields,
              let product = selectedProduct,
              let grams = parsedGrams(),
              grams > 0 else { return }

        isSyncingAmountFields = true
        let quantity = UnitConverter.quantity(fromGrams: grams, unit: unit, product: product)
        quantityText = formatAmount(quantity)
        isSyncingAmountFields = false
    }

    private func formatAmount(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}

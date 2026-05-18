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
    @State private var unit: MeasurementUnit = .gram

    private var selectedProduct: FoodProduct? {
        guard let key = selectedKey else { return nil }
        return products.first { $0.catalogKey == key }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("addIngredient.product") {
                    Picker("addIngredient.product", selection: $selectedKey) {
                        Text("addIngredient.selectProduct")
                            .tag(nil as String?)
                        ForEach(products, id: \.catalogKey) { product in
                            Text(LocalizedStringResource(stringLiteral: product.localizationKey))
                                .tag(product.catalogKey as String?)
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
                }
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

    private var canAdd: Bool {
        selectedProduct != nil && (Double(quantityText.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0
    }

    private func addIngredient() {
        guard let product = selectedProduct,
              let quantity = Double(quantityText.replacingOccurrences(of: ",", with: ".")),
              quantity > 0 else { return }

        onAdd(DraftIngredient(product: product, quantity: quantity, unit: unit))
        dismiss()
    }
}

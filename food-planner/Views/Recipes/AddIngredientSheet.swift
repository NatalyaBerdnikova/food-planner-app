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

    let onAdd: (DraftIngredient) -> Void
    var autofocusSearch: Bool = false

    @State private var selectedProduct: FoodProduct?
    @State private var quantityText: String
    @State private var unit: MeasurementUnit
    @State private var initialSearchText: String

    init(
        initialSearchText: String = "",
        initialQuantity: Double = 100,
        initialUnit: MeasurementUnit = .gram,
        autofocusSearch: Bool = false,
        onAdd: @escaping (DraftIngredient) -> Void
    ) {
        self.onAdd = onAdd
        self.autofocusSearch = autofocusSearch
        _quantityText = State(initialValue: Self.formatQuantity(initialQuantity))
        _unit = State(initialValue: initialUnit)
        _initialSearchText = State(initialValue: initialSearchText)
    }

    private static func formatQuantity(_ value: Double) -> String {
        value == floor(value) ? String(Int(value)) : String(value)
    }

    private enum ScrollAnchor {
        static let productSearch = "addIngredient.productSearch"
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                Form {
                    Section {
                        if let selectedProduct {
                            HStack {
                                Text(selectedProduct.displayName)
                                    .font(.body.weight(.medium))
                                Spacer()
                                Button {
                                    self.selectedProduct = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("common.cancel")
                            }
                        } else {
                            IngredientTagSearchField(
                                placeholder: "search.products",
                                initialSearchText: initialSearchText,
                                autofocus: autofocusSearch,
                                onSearchActivity: {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        proxy.scrollTo(ScrollAnchor.productSearch, anchor: .bottom)
                                    }
                                }
                            ) { product in
                                selectedProduct = product
                                initialSearchText = ""
                            }
                            .id(ScrollAnchor.productSearch)
                        }
                    } header: {
                        Text("addIngredient.product")
                    }

                    if selectedProduct != nil {
                        Section("addIngredient.amount") {
                            HStack {
                                Text("addIngredient.grams")
                                Spacer()
                                TextField("0", text: $quantityText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: 120)
                            }

                            Picker("unit.gram", selection: $unit) {
                                ForEach(MeasurementUnit.allCases, id: \.self) { item in
                                    Text(item.displayName).tag(item)
                                }
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
    }

    private var canAdd: Bool {
        selectedProduct != nil && (parsedQuantity() ?? 0) > 0
    }

    private func addIngredient() {
        guard let product = selectedProduct,
              let quantity = parsedQuantity(),
              quantity > 0 else { return }

        onAdd(DraftIngredient(product: product, quantity: quantity, unit: unit))
        dismiss()
    }

    private func parsedQuantity() -> Double? {
        Double(quantityText.replacingOccurrences(of: ",", with: "."))
    }
}

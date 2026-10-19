import SwiftUI

struct DraftIngredientRow: View {
    @Binding var draft: DraftIngredient
    var showsMatchedBadge: Bool = false

    @State private var showQuantityPicker = false
    @State private var pickerValue: Double = 100

    var body: some View {
        HStack(spacing: 10) {
            if showsMatchedBadge {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.success)
                    .accessibilityHidden(true)
            }

            Text(draft.product.displayName)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                pickerValue = Self.snappedPickerValue(draft.quantity, unit: draft.unit)
                showQuantityPicker = true
            } label: {
                Text(L10n.amount(quantity: draft.quantity, unit: draft.unit))
                    .foregroundStyle(Color.accentColor)
                    .monospacedDigit()
                    .frame(minWidth: 56, alignment: .trailing)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.amount(quantity: draft.quantity, unit: draft.unit))
            .accessibilityHint(Text("addIngredient.editQuantity.hint"))

            quantityControls
        }
        .sheet(isPresented: $showQuantityPicker) {
            quantityPickerSheet
        }
    }

    private var quantityPickerSheet: some View {
        NavigationStack {
            Picker("addIngredient.quantity", selection: $pickerValue) {
                ForEach(pickerValues, id: \.self) { value in
                    Text(L10n.amount(quantity: value, unit: draft.unit))
                        .tag(value)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .padding(.horizontal)
            .navigationTitle(draft.product.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") {
                        showQuantityPicker = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") {
                        draft.quantity = pickerValue
                        showQuantityPicker = false
                    }
                }
            }
        }
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
    }

    private var quantityControls: some View {
        HStack(spacing: 0) {
            Button(action: decrementQuantity) {
                Image(systemName: "minus")
                    .font(.body.weight(.semibold))
                    .frame(width: AppTheme.minTapTarget, height: AppTheme.minTapTarget)
                    .contentShape(Rectangle())
            }
            .disabled(draft.quantity <= minimumQuantity)
            .accessibilityLabel(Text("addIngredient.decreaseQuantity"))

            Button(action: incrementQuantity) {
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
                    .frame(width: AppTheme.minTapTarget, height: AppTheme.minTapTarget)
                    .contentShape(Rectangle())
            }
            .disabled(draft.quantity >= maximumQuantity)
            .accessibilityLabel(Text("addIngredient.increaseQuantity"))
        }
        .buttonStyle(.borderless)
        .foregroundStyle(Color.accentColor)
    }

    private var pickerValues: [Double] {
        Self.pickerValues(for: draft.unit)
    }

    private var minimumQuantity: Double {
        pickerValues.first ?? 1
    }

    private var maximumQuantity: Double {
        pickerValues.last ?? 100
    }

    private func incrementQuantity() {
        let next = draft.quantity + Self.step(forIncreasingFrom: draft.quantity, unit: draft.unit)
        draft.quantity = min(maximumQuantity, next)
    }

    private func decrementQuantity() {
        let next = draft.quantity - Self.step(forDecreasingFrom: draft.quantity, unit: draft.unit)
        draft.quantity = max(minimumQuantity, next)
    }

    static func pickerValues(for unit: MeasurementUnit) -> [Double] {
        switch unit {
        case .gram, .milliliter:
            Array(stride(from: 1.0, through: 2000.0, by: 1.0))
        case .kilogram, .liter:
            Array(stride(from: 0.1, through: 20.0, by: 0.1)).map { ($0 * 10).rounded() / 10 }
        case .piece, .tablespoon, .teaspoon:
            Array(stride(from: 1.0, through: 99.0, by: 1.0))
        }
    }

    static func snappedPickerValue(_ quantity: Double, unit: MeasurementUnit) -> Double {
        let values = pickerValues(for: unit)
        guard let first = values.first, let last = values.last else { return quantity }
        let clamped = min(max(quantity, first), last)
        return values.min(by: { abs($0 - clamped) < abs($1 - clamped) }) ?? clamped
    }

    static func step(forIncreasingFrom quantity: Double, unit: MeasurementUnit) -> Double {
        switch unit {
        case .gram, .milliliter:
            if quantity < 10 { return 1 }
            if quantity < 20 { return 2 }
            if quantity < 100 { return 5 }
            if quantity < 1000 { return 10 }
            return 100
        case .kilogram, .liter:
            return 0.1
        case .piece, .tablespoon, .teaspoon:
            return 1
        }
    }

    static func step(forDecreasingFrom quantity: Double, unit: MeasurementUnit) -> Double {
        switch unit {
        case .gram, .milliliter:
            if quantity <= 10 { return 1 }
            if quantity <= 20 { return 2 }
            if quantity <= 100 { return 5 }
            if quantity <= 1000 { return 10 }
            return 100
        case .kilogram, .liter:
            return 0.1
        case .piece, .tablespoon, .teaspoon:
            return 1
        }
    }
}

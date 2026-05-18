import SwiftUI
import SwiftData

struct AddRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var sourceURL = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var fat = ""
    @State private var carbs = ""
    @State private var stepsText = ""

    var body: some View {
        Form {
            Section("Основное") {
                TextField("Название", text: $name)
                TextField("Ссылка на источник", text: $sourceURL)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
            }

            Section("КБЖУ на 100 г") {
                TextField("Калории", text: $calories)
                    .keyboardType(.decimalPad)
                TextField("Белки", text: $protein)
                    .keyboardType(.decimalPad)
                TextField("Жиры", text: $fat)
                    .keyboardType(.decimalPad)
                TextField("Углеводы", text: $carbs)
                    .keyboardType(.decimalPad)
            }

            Section("Шаги") {
                TextField("Каждый шаг с новой строки", text: $stepsText, axis: .vertical)
                    .lineLimit(4...8)
            }
        }
        .navigationTitle("Новый рецепт")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Отмена") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить") { saveRecipe() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func saveRecipe() {
        let recipe = Recipe(
            name: name.trimmingCharacters(in: .whitespaces),
            sourceURL: sourceURL.isEmpty ? nil : sourceURL,
            steps: stepsText
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty },
            caloriesPer100g: Double(calories) ?? 0,
            proteinPer100g: Double(protein) ?? 0,
            fatPer100g: Double(fat) ?? 0,
            carbsPer100g: Double(carbs) ?? 0
        )
        modelContext.insert(recipe)
        dismiss()
    }
}

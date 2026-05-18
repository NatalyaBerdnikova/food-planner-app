import SwiftUI
import SwiftData

struct AddMealSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let dayPlan: DayPlan
    let onSave: () -> Void

    @State private var mealType: MealType = .breakfast
    @State private var selectedRecipe: Recipe?
    @State private var showRecipePicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Приём пищи") {
                    Picker("Тип", selection: $mealType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                Section("Рецепт") {
                    Button {
                        showRecipePicker = true
                    } label: {
                        HStack {
                            Text(selectedRecipe?.name ?? "Выбрать рецепт")
                                .foregroundStyle(selectedRecipe == nil ? .accentColor : .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .navigationTitle("Новый приём пищи")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") { saveMeal() }
                        .disabled(selectedRecipe == nil)
                }
            }
            .navigationDestination(isPresented: $showRecipePicker) {
                RecipePickerView(selectedRecipe: $selectedRecipe)
            }
        }
    }

    private func saveMeal() {
        guard let recipe = selectedRecipe else { return }

        let meal = Meal(
            mealType: mealType,
            date: dayPlan.date,
            recipe: recipe,
            dayPlan: dayPlan
        )
        modelContext.insert(meal)
        dayPlan.meals.append(meal)

        if let weekPlan = dayPlan.weekPlan {
            WeekPlanService.syncShoppingItems(for: weekPlan, in: modelContext)
        }

        onSave()
        dismiss()
    }
}

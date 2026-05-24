import PhotosUI
import SwiftUI
import SwiftData

struct AddRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var stepsText = ""
    @State private var imageData: Data?
    @State private var draftIngredients: [DraftIngredient] = []
    @State private var showAddIngredient = false
    @State private var photoPickerItem: PhotosPickerItem?

    private var previewNutrition: RecipeNutrition? {
        guard !draftIngredients.isEmpty else { return nil }
        var totalWeight = 0.0
        var totals = NutrientTotals.zero
        for draft in draftIngredients {
            let grams = UnitConverter.grams(
                quantity: draft.quantity,
                unit: draft.unit,
                product: draft.product
            )
            guard grams > 0 else { continue }
            totalWeight += grams
            totals = totals + draft.product.nutrientsPer100g.scaled(by: grams / 100.0)
        }
        guard totalWeight > 0 else { return nil }
        return RecipeNutrition(
            total: totals,
            totalWeightGrams: totalWeight,
            per100g: totals.per100g(totalWeightGrams: totalWeight)
        )
    }

    var body: some View {
        Form {
            Section("addRecipe.photo") {
                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    Label("addRecipe.pickPhoto", systemImage: "photo.on.rectangle")
                }

                if imageData != nil {
                    RecipeImageView(imageData: imageData, cornerRadius: 8)
                        .frame(height: 120)
                }
            }

            Section("addRecipe.main") {
                TextField("addRecipe.name", text: $name)
            }

            Section {
                TextEditor(text: $stepsText)
                    .frame(minHeight: 140)
                    .overlay(alignment: .topLeading) {
                        if stepsText.isEmpty {
                            Text("addRecipe.stepsPlaceholder")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }
            } header: {
                Text("addRecipe.steps")
            } footer: {
                Text("addRecipe.stepsFooter")
            }

            Section("addRecipe.ingredients") {
                ForEach(draftIngredients) { draft in
                    HStack {
                        Text(draft.product.displayName)
                        Spacer()
                        Text(L10n.amount(quantity: draft.quantity, unit: draft.unit))
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { draftIngredients.remove(atOffsets: $0) }

                Button {
                    showAddIngredient = true
                } label: {
                    Label("addRecipe.addIngredient", systemImage: "plus.circle")
                }
            }

            if let nutrition = previewNutrition, nutrition.totalWeightGrams > 0 {
                Section("addRecipe.nutrition") {
                    NutritionSummaryView(
                        nutrition: nutrition.per100g.macros,
                        title: "nutrition.title.per100g"
                    )
                    Text(L10n.recipeTotalCalories(Int(nutrition.total.calories.rounded())))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("addRecipe.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("common.cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("common.save") { saveRecipe() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .sheet(isPresented: $showAddIngredient) {
            AddIngredientSheet { draft in
                draftIngredients.append(draft)
            }
        }
        .onChange(of: photoPickerItem) { _, item in
            loadPhoto(from: item)
        }
    }

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run { imageData = data }
            }
        }
    }

    private func saveRecipe() {
        let recipe = Recipe(
            name: name.trimmingCharacters(in: .whitespaces),
            imageData: imageData,
            steps: stepsText
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        )
        modelContext.insert(recipe)

        for draft in draftIngredients {
            let ingredient = Ingredient(
                name: draft.product.displayName,
                quantity: draft.quantity,
                unit: draft.unit,
                category: draft.product.category,
                recipe: recipe,
                foodProduct: draft.product
            )
            modelContext.insert(ingredient)
            recipe.ingredients.append(ingredient)
        }

        recipe.recalculateNutrition()
        LocalPersistence.save(modelContext)
        dismiss()
    }
}

import PhotosUI
import SwiftUI
import SwiftData
import UIKit

struct ImportedRecipeReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String
    @State private var servings: Int
    @State private var stepsAttributed: NSAttributedString
    @State private var imageData: Data?
    @State private var sourceURL: String
    @State private var draftIngredients: [DraftIngredient]
    @State private var unresolvedIngredients: [UnresolvedIngredient]
    @State private var showAddIngredient = false
    @State private var resolvingUnresolved: UnresolvedIngredient?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var didSave = false

    init(draft: ImportedRecipeDraft) {
        _name = State(initialValue: draft.name)
        _servings = State(initialValue: max(draft.servings ?? 1, 1))
        _stepsAttributed = State(
            initialValue: RecipeStepsStorage.attributedString(fromPlainSteps: draft.steps)
        )
        _imageData = State(initialValue: draft.imageData)
        _sourceURL = State(initialValue: draft.sourceURL ?? "")
        _draftIngredients = State(initialValue: draft.ingredients)
        _unresolvedIngredients = State(initialValue: draft.unresolvedIngredients)
    }

    private var previewNutritionPerServing: DailyNutrition? {
        guard !draftIngredients.isEmpty else { return nil }
        var totals = NutrientTotals.zero
        for draft in draftIngredients {
            let grams = UnitConverter.grams(
                quantity: draft.quantity,
                unit: draft.unit,
                product: draft.product
            )
            guard grams > 0 else { continue }
            totals = totals + draft.product.nutrientsPer100g.scaled(by: grams / 100.0)
        }
        guard totals.calories > 0 || totals.protein > 0 else { return nil }
        let divisor = max(Double(servings), 1)
        return DailyNutrition(
            calories: totals.calories / divisor,
            protein: totals.protein / divisor,
            fat: totals.fat / divisor,
            carbs: totals.carbs / divisor
        )
    }

    var body: some View {
        Form {
            Section {
                Label("import.review.aiBadge", systemImage: "sparkles")
                    .foregroundStyle(AppTheme.accent)
                    .font(.subheadline.weight(.semibold))
                Text("import.review.aiHint")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("import.privacy.server")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("addRecipe.photo") {
                if imageData != nil {
                    RecipeImageView(
                        imageData: imageData,
                        cornerRadius: 12,
                        pointSize: CGSize(width: 390, height: 180)
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .clipped()
                    .listRowInsets(EdgeInsets())
                }

                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    Label("addRecipe.pickPhoto", systemImage: "photo.on.rectangle")
                }
            }

            Section {
                TextField("addRecipe.name", text: $name)
                Stepper(value: $servings, in: 1...99) {
                    Text("addRecipe.servings \(servings)")
                }
            } header: {
                Text("addRecipe.main")
            }

            if !sourceURL.isEmpty {
                Section("addRecipe.sourceURL") {
                    if let url = URL(string: sourceURL) {
                        Link(destination: url) {
                            Label(sourceURL, systemImage: "link")
                                .lineLimit(2)
                        }
                    } else {
                        Text(sourceURL)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                RichTextEditorView(attributedText: $stepsAttributed)
            } header: {
                Text("addRecipe.steps")
            }

            Section {
                ForEach(draftIngredients) { draft in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.success)
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
            } header: {
                Text("import.review.matched \(draftIngredients.count)")
            }

            if !unresolvedIngredients.isEmpty {
                Section {
                    ForEach(unresolvedIngredients) { item in
                        Button {
                            resolvingUnresolved = item
                        } label: {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(AppTheme.warning)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.rawName)
                                    Text("import.unresolved.tap")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(L10n.amount(quantity: item.suggestedQuantity, unit: item.suggestedUnit))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("import.unresolved.title")
                } footer: {
                    Text("import.unresolved.footer")
                }
            }

            if let nutrition = previewNutritionPerServing {
                Section("addRecipe.nutrition") {
                    NutritionSummaryView(
                        nutrition: nutrition,
                        title: "nutrition.title.perServing"
                    )
                }
            }
        }
        .navigationTitle("import.review.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("import.review.discard") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("common.save") { saveRecipe() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .sensoryFeedback(.success, trigger: didSave)
        .sheet(isPresented: $showAddIngredient) {
            AddIngredientSheet { draft in
                draftIngredients.append(draft)
            }
        }
        .sheet(item: $resolvingUnresolved) { item in
            AddIngredientSheet(
                initialSearchText: item.rawName,
                initialQuantity: item.suggestedQuantity,
                initialUnit: item.suggestedUnit
            ) { draft in
                draftIngredients.append(draft)
                unresolvedIngredients.removeAll { $0.id == item.id }
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
        let trimmedSourceURL = sourceURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let recipe = Recipe(
            name: name.trimmingCharacters(in: .whitespaces),
            userRecipeId: UUID().uuidString,
            servings: servings,
            imageData: imageData,
            sourceURL: trimmedSourceURL.isEmpty ? nil : trimmedSourceURL,
            steps: RecipeStepsStorage.plainStepLines(from: stepsAttributed),
            stepsRichTextData: RecipeStepsStorage.rtfData(from: stepsAttributed)
        )
        modelContext.insert(recipe)

        for draft in draftIngredients {
            let ingredient = Ingredient(
                name: draft.product.catalogKey,
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
        RecipeCatalogStore.persistUserRecipes(in: modelContext)
        didSave = true
        dismiss()
    }
}

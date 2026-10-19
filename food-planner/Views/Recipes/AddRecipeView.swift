import PhotosUI
import SwiftUI
import SwiftData
import UIKit

struct AddRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var name: String
    @State private var servings: Int
    @State private var cookTimeMinutes: Int
    @State private var mealTypeTags: Set<MealType>
    @State private var stepsAttributed: NSAttributedString
    @State private var imageData: Data?
    @State private var sourceURL: String
    @State private var draftIngredients: [DraftIngredient]
    @State private var unresolvedIngredients: [UnresolvedIngredient]
    @State private var resolvingUnresolved: UnresolvedIngredient?
    @State private var photoPickerItem: PhotosPickerItem?

    init(prefill: ImportedRecipeDraft? = nil) {
        _name = State(initialValue: prefill?.name ?? "")
        _servings = State(initialValue: max(prefill?.servings ?? 1, 1))
        _cookTimeMinutes = State(initialValue: max(prefill?.cookTimeMinutes ?? 0, 0))
        _mealTypeTags = State(initialValue: [])
        _stepsAttributed = State(
            initialValue: RecipeStepsStorage.attributedString(fromPlainSteps: prefill?.steps ?? [])
        )
        _imageData = State(initialValue: prefill?.imageData)
        _sourceURL = State(initialValue: prefill?.sourceURL ?? "")
        _draftIngredients = State(initialValue: prefill?.ingredients ?? [])
        _unresolvedIngredients = State(initialValue: prefill?.unresolvedIngredients ?? [])
    }

    private var previewNutritionPerServing: DailyNutrition {
        guard !draftIngredients.isEmpty else { return .zero }
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
        let divisor = max(Double(servings), 1)
        return DailyNutrition(
            calories: totals.calories / divisor,
            protein: totals.protein / divisor,
            fat: totals.fat / divisor,
            carbs: totals.carbs / divisor
        )
    }

    private enum ScrollAnchor {
        static let ingredientSearch = "addRecipe.ingredientSearch"
    }

    var body: some View {
        ScrollViewReader { proxy in
            Form {
                RecipePhotoPickerSection(
                    imageData: $imageData,
                    photoPickerItem: $photoPickerItem
                )

                Section {
                    TextField("addRecipe.name", text: $name)
                    Stepper(value: $servings, in: 1...99) {
                        Text("addRecipe.servings \(servings)")
                    }
                    Stepper(value: $cookTimeMinutes, in: 0...300, step: 5) {
                        if cookTimeMinutes > 0 {
                            Text("addRecipe.cookTime \(cookTimeMinutes)")
                        } else {
                            Text("addRecipe.cookTime.unknown")
                        }
                    }
                    RecipeMealTypeTagsPicker(selected: $mealTypeTags)
                } header: {
                    Text("addRecipe.main")
                } footer: {
                    Text("addRecipe.servingsFooter")
                }

                if !sourceURL.isEmpty {
                    Section("addRecipe.sourceURL") {
                        if let url = URL(string: sourceURL) {
                            Link(sourceURL, destination: url)
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
                    ForEach($draftIngredients) { $draft in
                        DraftIngredientRow(draft: $draft)
                    }
                    .onDelete { draftIngredients.remove(atOffsets: $0) }

                    IngredientTagSearchField(
                        excludedCatalogKeys: Set(draftIngredients.map(\.product.catalogKey)),
                        placeholder: "addRecipe.addIngredient",
                        onSearchActivity: {
                            scrollIngredientSearchToTop(proxy)
                        }
                    ) { product in
                        draftIngredients.append(
                            DraftIngredient(product: product, quantity: 100, unit: .gram)
                        )
                        scrollIngredientSearchToTop(proxy)
                    }
                    .id(ScrollAnchor.ingredientSearch)
                } header: {
                    Text("addRecipe.ingredients")
                }

                if !unresolvedIngredients.isEmpty {
                    Section {
                        ForEach(unresolvedIngredients) { item in
                            Button {
                                resolvingUnresolved = item
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.rawName)
                                            .foregroundStyle(.primary)
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

                Section("addRecipe.nutrition") {
                    NutritionSummaryView(
                        nutrition: previewNutritionPerServing,
                        title: "nutrition.title.perServing",
                        embedded: true,
                        macroLabelStyle: .full
                    )
                    .listRowInsets(
                        EdgeInsets(
                            top: AppTheme.cardPadding,
                            leading: AppTheme.cardPadding,
                            bottom: AppTheme.cardPadding,
                            trailing: AppTheme.cardPadding
                        )
                    )
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                            .fill(AppTheme.elevated)
                    )
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
    }

    private func scrollIngredientSearchToTop(_ proxy: ScrollViewProxy) {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
            proxy.scrollTo(ScrollAnchor.ingredientSearch, anchor: .top)
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
            stepsRichTextData: RecipeStepsStorage.rtfData(from: stepsAttributed),
            cookTimeMinutes: cookTimeMinutes,
            mealTypeTags: mealTypeTags
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
        dismiss()
    }
}

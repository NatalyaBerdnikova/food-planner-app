import SwiftUI
import SwiftData

struct PlannedMealSlotView: View {
    let mealType: MealType
    let meals: [Meal]
    var onTap: () -> Void

    private var recipes: [Recipe] {
        meals.compactMap(\.recipe)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onTap) {
                HStack(spacing: 10) {
                    Image(systemName: iconName)
                        .foregroundStyle(.tint)
                        .frame(width: 24)

                    Text(mealTypeLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Image(systemName: recipes.isEmpty ? "plus.circle" : "pencil.circle")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if recipes.isEmpty {
                Button(action: onTap) {
                    Text("home.notPlanned")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            } else {
                ForEach(recipes) { recipe in
                    NavigationLink {
                        RecipeDetailView(recipe: recipe)
                    } label: {
                        recipeLine(recipe)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func recipeLine(_ recipe: Recipe) -> some View {
        HStack(spacing: 10) {
            RecipeImageView(imageData: recipe.imageData, cornerRadius: 8)
                .frame(width: 44, height: 44)

            Text(recipe.name)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            let nutrition = NutritionCalculator.recipeNutrition(recipe)
            let calories = nutrition.totalWeightGrams > 0
                ? Int(nutrition.total.calories.rounded())
                : Int(recipe.caloriesPer100g)
            Text(L10n.kcalShort(calories))
                .font(.caption)
                .foregroundStyle(.secondary)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }

    private var mealTypeLabel: LocalizedStringResource {
        mealType == .snack ? "filter.other" : mealType.displayName
    }

    private var iconName: String {
        switch mealType {
        case .breakfast: "sunrise.fill"
        case .lunch: "sun.max.fill"
        case .dinner: "moon.stars.fill"
        case .snack: "ellipsis.circle.fill"
        }
    }
}

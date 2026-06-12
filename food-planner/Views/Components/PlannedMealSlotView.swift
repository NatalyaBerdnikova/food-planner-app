import SwiftUI
import SwiftData

enum PlannedMealSlotStyle {
    case regular
    case home
}

struct PlannedMealSlotView: View {
    let mealType: MealType
    let meals: [Meal]
    var onTap: () -> Void
    var style: PlannedMealSlotStyle = .regular

    private var recipes: [Recipe] {
        meals.compactMap(\.recipe)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onTap) {
                HStack(spacing: 10) {
                    Image(systemName: iconName)
                        .foregroundStyle(style == .home ? .white.opacity(0.9) : Color.accentColor)
                        .frame(width: 24)

                    Text(mealTypeLabel)
                        .font(.caption)
                        .foregroundStyle(style == .home ? .white.opacity(0.85) : .secondary)

                    Spacer()

                    Image(systemName: recipes.isEmpty ? "plus.circle" : "pencil.circle")
                        .font(.caption)
                        .foregroundStyle(style == .home ? .white.opacity(0.75) : Color(UIColor.tertiaryLabel))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if recipes.isEmpty {
                Button(action: onTap) {
                    Text("home.notPlanned")
                        .font(.subheadline)
                        .foregroundStyle(style == .home ? .white.opacity(0.8) : .secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
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
        .background(backgroundStyle)
        .clipShape(RoundedRectangle(cornerRadius: style == .home ? 14 : 10))
        .overlay {
            if style == .home {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            }
        }
        .shadow(
            color: style == .home ? Color.black.opacity(0.12) : .clear,
            radius: style == .home ? 10 : 0,
            y: style == .home ? 4 : 0
        )
    }

    private func recipeLine(_ recipe: Recipe) -> some View {
        HStack(spacing: 10) {
            RecipeImageView(imageData: recipe.imageData, cornerRadius: 8)
                .frame(width: style == .home ? 50 : 44, height: style == .home ? 50 : 44)

            Text(recipe.name)
                .font(.subheadline)
                .foregroundStyle(style == .home ? .white : .primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            let nutrition = NutritionCalculator.recipeNutrition(recipe)
            let calories = nutrition.totalWeightGrams > 0
                ? Int(nutrition.total.calories.rounded())
                : Int(recipe.caloriesPer100g)
            Text(L10n.kcalShort(calories))
                .font(.caption)
                .foregroundStyle(style == .home ? .white.opacity(0.85) : .secondary)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(style == .home ? .white.opacity(0.75) : Color(UIColor.tertiaryLabel))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var mealTypeLabel: LocalizedStringResource {
        mealType == .snack ? "filter.other" : mealType.displayName
    }

    @ViewBuilder
    private var backgroundStyle: some View {
        if style == .home {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.31, blue: 0.40), Color(red: 0.04, green: 0.22, blue: 0.32)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color(.tertiarySystemBackground)
        }
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

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

    private let accentTeal = Color(red: 0.06, green: 0.33, blue: 0.45)

    private var recipes: [Recipe] {
        meals.compactMap(\.recipe)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onTap) {
                HStack(spacing: 10) {
                    Image(systemName: iconName)
                        .foregroundStyle(style == .home ? accentTeal : Color.accentColor)
                        .frame(width: 30, height: 30)
                        .background(
                            style == .home ? accentTeal.opacity(0.1) : Color.clear,
                            in: Circle()
                        )

                    Text(mealTypeLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: recipes.isEmpty ? "plus.circle.fill" : "pencil.circle.fill")
                        .font(.body)
                        .foregroundStyle(style == .home ? accentTeal : Color(UIColor.tertiaryLabel))
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
                        .padding(12)
                        .background(
                            Color(.tertiarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
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
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundStyle)
        .clipShape(RoundedRectangle(cornerRadius: style == .home ? 22 : 10, style: .continuous))
        .overlay {
            if style == .home {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            }
        }
    }

    private func recipeLine(_ recipe: Recipe) -> some View {
        HStack(spacing: 12) {
            RecipeImageView(imageData: recipe.imageData, cornerRadius: 10)
                .frame(width: 48, height: 48)
                .clipped()

            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                let nutrition = NutritionCalculator.nutritionPerServing(for: recipe)
                Text(macroSummary(nutrition))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color(UIColor.tertiaryLabel))
        }
        .padding(12)
        .background(
            Color(.tertiarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func macroSummary(_ nutrition: DailyNutrition) -> String {
        let kcal = formatted(nutrition.calories)
        let protein = formatted(nutrition.protein)
        let fat = formatted(nutrition.fat)
        let carbs = formatted(nutrition.carbs)
        return "\(kcal) · \(protein) · \(fat) · \(carbs)"
    }

    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }

    private var mealTypeLabel: LocalizedStringResource {
        mealType == .snack ? "filter.other" : mealType.displayName
    }

    @ViewBuilder
    private var backgroundStyle: some View {
        if style == .home {
            Color(.secondarySystemGroupedBackground)
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

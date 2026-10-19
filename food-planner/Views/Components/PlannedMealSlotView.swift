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

    @AppStorage(MacroDisplaySettings.showFractionsKey) private var showMacroFractions =
        MacroDisplaySettings.showFractionsDefault

    private var recipes: [Recipe] {
        meals.compactMap(\.recipe)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: style == .home ? 10 : 8) {
            Button(action: onTap) {
                HStack(spacing: 10) {
                    Image(systemName: iconName)
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: AppTheme.minTapTarget, height: AppTheme.minTapTarget)
                        .background(AppTheme.accent.opacity(0.12), in: Circle())

                    Text(mealTypeLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer(minLength: 8)

                    Image(systemName: recipes.isEmpty ? "plus.circle.fill" : "pencil.circle.fill")
                        .font(.body)
                        .foregroundStyle(style == .home ? AppTheme.accent : Color(UIColor.tertiaryLabel))
                        .frame(minWidth: AppTheme.minTapTarget, minHeight: AppTheme.minTapTarget)
                }
                .frame(minHeight: AppTheme.minTapTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(mealTypeLabel)
            .accessibilityHint(Text(recipes.isEmpty ? "accessibility.addMeal" : "accessibility.editMeal"))

            if recipes.isEmpty {
                Button(action: onTap) {
                    Text("home.notPlanned")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                        .background(
                            AppTheme.nestedFill,
                            in: RoundedRectangle(cornerRadius: nestedRowRadius, style: .continuous)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 8) {
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
        }
        .padding(style == .home ? 14 : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundStyle)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
    }

    private var nestedRowRadius: CGFloat {
        style == .home ? 12 : AppTheme.nestedCardRadius
    }

    private func recipeLine(_ recipe: Recipe) -> some View {
        HStack(spacing: 12) {
            RecipeImageView(imageData: recipe.imageData, cornerRadius: 10)
                .frame(width: 52, height: 52)
                .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.localizedName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                    if recipe.hasCookTime {
                        Text("recipe.cookTime \(recipe.cookTimeMinutes)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.accent)
                    }
                    let nutrition = NutritionCalculator.nutritionPerServing(for: recipe)
                    Text(macroSummary(nutrition))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color(UIColor.tertiaryLabel))
        }
        .padding(12)
        .background(
            AppTheme.nestedFill,
            in: RoundedRectangle(cornerRadius: nestedRowRadius, style: .continuous)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func macroSummary(_ nutrition: DailyNutrition) -> String {
        let kcalUnit = String(localized: "nutrition.unit.kcal")
        let proteinLabel = String(localized: "nutrition.macro.protein").lowercased()
        let fatLabel = String(localized: "nutrition.macro.fat").lowercased()
        let carbsLabel = String(localized: "nutrition.macro.carbs").lowercased()
        let kcal = "\(formatted(nutrition.calories)) \(kcalUnit)"
        let protein = "\(formatted(nutrition.protein)) \(proteinLabel)"
        let fat = "\(formatted(nutrition.fat)) \(fatLabel)"
        let carbs = "\(formatted(nutrition.carbs)) \(carbsLabel)"
        return "\(kcal) · \(protein) · \(fat) · \(carbs)"
    }

    private func formatted(_ value: Double) -> String {
        MacroDisplaySettings.format(value, showFractions: showMacroFractions)
    }

    private var mealTypeLabel: LocalizedStringResource {
        mealType == .snack ? "filter.other" : mealType.displayName
    }

    @ViewBuilder
    private var backgroundStyle: some View {
        if style == .home {
            AppTheme.elevated
        } else {
            Color.clear
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

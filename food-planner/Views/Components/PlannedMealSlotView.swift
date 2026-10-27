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
    var allowsEditing: Bool = true
    var opensRecipeInPreviewMode: Bool = false
    var lockedEditHint: LocalizedStringKey? = nil

    @AppStorage(MacroDisplaySettings.showFractionsKey) private var showMacroFractions =
        MacroDisplaySettings.showFractionsDefault
    @State private var showLockedHint = false
    @State private var lockedHintTask: Task<Void, Never>?

    private var recipes: [Recipe] {
        meals.compactMap(\.recipe)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: style == .home ? 10 : 8) {
            mealTypeHeader

            if recipes.isEmpty {
                if allowsEditing {
                    Button(action: handleEditTap) {
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
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(recipes) { recipe in
                        NavigationLink {
                            RecipeDetailView(
                                recipe: recipe,
                                isPreviewPresentation: opensRecipeInPreviewMode
                            )
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
        .overlay(alignment: .topTrailing) {
            if showLockedHint, let lockedEditHint {
                Text(lockedEditHint)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.regularMaterial, in: Capsule())
                    .shadow(color: .black.opacity(0.1), radius: 6, y: 2)
                    .padding(.trailing, 4)
                    .padding(.top, 36)
                    .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .topTrailing)))
                    .allowsHitTesting(false)
                    .accessibilityAddTraits(.isStaticText)
            }
        }
        .animation(.easeOut(duration: 0.12), value: showLockedHint)
        .onDisappear {
            lockedHintTask?.cancel()
        }
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
    private var mealTypeHeader: some View {
        let row = HStack(spacing: 10) {
            Image(systemName: iconName)
                .foregroundStyle(AppTheme.accent)
                .frame(width: AppTheme.minTapTarget, height: AppTheme.minTapTarget)
                .background(AppTheme.accent.opacity(0.12), in: Circle())

            Text(mealTypeLabel)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer(minLength: 8)

            if allowsEditing {
                Image(systemName: recipes.isEmpty ? "plus.circle.fill" : "pencil.circle.fill")
                    .font(.body)
                    .foregroundStyle(style == .home ? AppTheme.accent : Color(UIColor.tertiaryLabel))
                    .frame(minWidth: AppTheme.minTapTarget, minHeight: AppTheme.minTapTarget)
            }
        }
        .frame(minHeight: AppTheme.minTapTarget)

        if allowsEditing {
            Button(action: handleEditTap) {
                row
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(mealTypeLabel)
            .accessibilityHint(
                lockedEditHint != nil
                    ? Text(lockedEditHint!)
                    : Text(recipes.isEmpty ? "accessibility.addMeal" : "accessibility.editMeal")
            )
        } else {
            row
                .accessibilityElement(children: .combine)
                .accessibilityLabel(mealTypeLabel)
        }
    }

    private func handleEditTap() {
        guard lockedEditHint != nil else {
            onTap()
            return
        }
        presentLockedHint()
    }

    private func presentLockedHint() {
        lockedHintTask?.cancel()
        showLockedHint = true
        lockedHintTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1400))
            guard !Task.isCancelled else { return }
            showLockedHint = false
        }
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

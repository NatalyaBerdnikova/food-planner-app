import SwiftUI

enum RecipeCardBadge {
    case favorite
}

enum RecipeCardStyle {
    case grid
    case rail
    case hero
}

enum RecipeCardImageMeta {
    case cookTimeTopLeading
    case caloriesTopLeading
    case libraryBottomLeading
}

struct RecipeCardView: View {
    let recipe: Recipe
    var badge: RecipeCardBadge?
    var style: RecipeCardStyle = .grid
    var showsNutrition: Bool = false
    var showsCommunityLikes: Bool = false
    var imageMeta: RecipeCardImageMeta = .cookTimeTopLeading
    var showsFavoriteControl: Bool = false
    var isFavorite: Bool = false
    var onFavoriteTap: (() -> Void)?

    @AppStorage(MacroDisplaySettings.showFractionsKey) private var showMacroFractions =
        MacroDisplaySettings.showFractionsDefault

    private var nutritionPerServing: DailyNutrition {
        NutritionCalculator.nutritionPerServing(for: recipe)
    }

    private var imageHeight: CGFloat {
        switch style {
        case .grid:
            showsNutrition ? AppTheme.recipeCardCompactImageHeight : AppTheme.recipeCardImageHeight
        case .rail:
            AppTheme.recipeCardImageHeight
        case .hero:
            AppTheme.recipeHeroCardHeight
        }
    }

    private var imagePointSize: CGSize {
        switch style {
        case .hero:
            CGSize(width: 720, height: 480)
        case .rail, .grid:
            CGSize(width: 480, height: 360)
        }
    }

    private var titleFont: Font {
        style == .hero ? .title3.weight(.semibold) : .subheadline.weight(.semibold)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageSection

            VStack(alignment: .leading, spacing: 8) {
                titleRow

                if showsNutrition {
                    HStack(spacing: 6) {
                        macroChip(title: "nutrition.macro.protein", value: nutritionPerServing.protein)
                        macroChip(title: "nutrition.macro.fat", value: nutritionPerServing.fat)
                        macroChip(title: "nutrition.macro.carbs", value: nutritionPerServing.carbs)
                    }
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.elevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .shadow(color: AppTheme.cardShadow, radius: 8, x: 0, y: 3)
        .contentShape(Rectangle())
    }

    private var imageSection: some View {
        ZStack {
            RecipeImageView(
                imageData: recipe.imageData,
                cornerRadius: 0,
                pointSize: imagePointSize
            )

            imageMetaOverlay

            overlayTrailingControls
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: imageHeight)
        .clipped()
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: AppTheme.cardRadius,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: AppTheme.cardRadius,
                style: .continuous
            )
        )
    }

    @ViewBuilder
    private var imageMetaOverlay: some View {
        switch imageMeta {
        case .cookTimeTopLeading:
            if recipe.hasCookTime {
                RecipeCookTimeTag(minutes: recipe.cookTimeMinutes, usesMaterial: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(10)
                    .allowsHitTesting(false)
            }
        case .caloriesTopLeading:
            RecipeCaloriesTag(calories: nutritionPerServing.calories, usesMaterial: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(10)
                .allowsHitTesting(false)
        case .libraryBottomLeading:
            ZStack {
                if recipe.hasCookTime {
                    RecipeCookTimeTag(minutes: recipe.cookTimeMinutes, usesMaterial: true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                RecipeCaloriesTag(calories: nutritionPerServing.calories, usesMaterial: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
            .padding(10)
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var overlayTrailingControls: some View {
        HStack(spacing: 4) {
            if let badge {
                badgeIcon(for: badge)
            }
            if showsFavoriteControl {
                Button {
                    onFavoriteTap?()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isFavorite ? .red : .primary)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    isFavorite
                        ? String(localized: "accessibility.removeFavorite")
                        : String(localized: "accessibility.addFavorite")
                )
            }
        }
    }

    private var titleLineLimit: Int {
        style == .hero ? 3 : 2
    }

    private var titleRow: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(recipe.localizedName)
                .font(titleFont)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(titleLineLimit, reservesSpace: style != .hero)
                .frame(maxWidth: .infinity, alignment: .topLeading)

            if showsCommunityLikes {
                RecipeCommunityLikesTag(count: recipe.communityLikeCount)
            }
        }
    }

    private func macroChip(title: LocalizedStringResource, value: Double) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(formatted(value))
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(AppTheme.tagChipFill, in: RoundedRectangle(cornerRadius: AppTheme.tagChipRadius, style: .continuous))
    }

    private func formatted(_ value: Double) -> String {
        MacroDisplaySettings.format(value, showFractions: showMacroFractions)
    }

    @ViewBuilder
    private func badgeIcon(for badge: RecipeCardBadge) -> some View {
        switch badge {
        case .favorite:
            Image(systemName: "heart.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.red)
                .frame(width: 34, height: 34)
                .background(.ultraThinMaterial, in: Circle())
                .accessibilityHidden(true)
        }
    }
}

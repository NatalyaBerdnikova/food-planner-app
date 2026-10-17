import SwiftUI

enum RecipeCardBadge {
    case userCreated
    case favorite
}

struct RecipeCardView: View {
    let recipe: Recipe
    var badge: RecipeCardBadge?
    var showsFavoriteControl: Bool = false
    var isFavorite: Bool = false
    var onFavoriteTap: (() -> Void)?

    private var nutritionPerServing: DailyNutrition {
        NutritionCalculator.nutritionPerServing(for: recipe)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                RecipeImageView(
                    imageData: recipe.imageData,
                    cornerRadius: 0,
                    pointSize: CGSize(width: 200, height: 140)
                )
                .frame(maxWidth: .infinity)
                .frame(height: 124)
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
                .padding(8)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(recipe.localizedName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                    .frame(minHeight: 36, alignment: .topLeading)

                HStack(spacing: 6) {
                    macroChip(title: "nutrition.macro.kcal", value: nutritionPerServing.calories)
                    macroChip(title: "nutrition.macro.protein", value: nutritionPerServing.protein)
                    macroChip(title: "nutrition.macro.fat", value: nutritionPerServing.fat)
                    macroChip(title: "nutrition.macro.carbs", value: nutritionPerServing.carbs)
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.elevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .contentShape(Rectangle())
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
        .background(AppTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }

    @ViewBuilder
    private func badgeIcon(for badge: RecipeCardBadge) -> some View {
        let symbol: String = switch badge {
        case .userCreated: "person.crop.circle.fill"
        case .favorite: "heart.fill"
        }
        let color: Color = switch badge {
        case .userCreated: AppTheme.accent
        case .favorite: .red
        }
        Image(systemName: symbol)
            .font(.caption.weight(.bold))
            .foregroundStyle(color)
            .frame(width: 34, height: 34)
            .background(.ultraThinMaterial, in: Circle())
            .accessibilityHidden(true)
    }
}

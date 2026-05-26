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

    private var displayCaloriesPer100g: Double {
        let nutrition = NutritionCalculator.recipeNutrition(recipe)
        return nutrition.totalWeightGrams > 0
            ? nutrition.per100g.calories
            : recipe.caloriesPer100g
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                RecipeImageView(imageData: recipe.imageData)
                    .frame(height: 100)
                    .clipped()

                Text(recipe.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                Text(L10n.kcalPer100g(Int(displayCaloriesPer100g)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

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
                            .foregroundStyle(isFavorite ? .red : .secondary)
                            .padding(8)
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
            .padding(6)
        }
    }

    @ViewBuilder
    private func badgeIcon(for badge: RecipeCardBadge) -> some View {
        let symbol: String = switch badge {
        case .userCreated: "person.crop.circle.fill"
        case .favorite: "heart.fill"
        }
        let color: Color = switch badge {
        case .userCreated: .secondary
        case .favorite: .red
        }
        Image(systemName: symbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(6)
            .background(.ultraThinMaterial, in: Circle())
            .accessibilityHidden(true)
    }
}

import SwiftUI

struct RecipeMetaTag: View {
    let systemImage: String
    let text: String
    var tint: Color = AppTheme.accent

    var body: some View {
        Label {
            Text(text)
                .lineLimit(1)
        } icon: {
            Image(systemName: systemImage)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(AppTheme.tagChipFill, in: RoundedRectangle(cornerRadius: AppTheme.tagChipRadius, style: .continuous))
    }
}

struct RecipeMaterialMetaTag: View {
    let systemImage: String
    var text: String? = nil
    var tint: Color = .primary

    var body: some View {
        Group {
            if let text {
                Label {
                    Text(text)
                        .lineLimit(1)
                } icon: {
                    Image(systemName: systemImage)
                }
            } else {
                Image(systemName: systemImage)
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

struct RecipeCookTimeTag: View {
    let minutes: Int
    var usesMaterial: Bool = false

    var body: some View {
        if minutes > 0 {
            let text = String(localized: "recipe.cookTime \(minutes)")
            if usesMaterial {
                RecipeMaterialMetaTag(systemImage: "clock", text: text)
            } else {
                RecipeMetaTag(systemImage: "clock", text: text)
            }
        }
    }
}

struct RecipeCaloriesTag: View {
    let calories: Double
    var usesMaterial: Bool = false

    private var text: String {
        String(localized: "nutrition.kcalShort \(Int(calories.rounded()))")
    }

    var body: some View {
        if usesMaterial {
            RecipeMaterialMetaTag(systemImage: "flame.fill", text: text)
        } else {
            RecipeMetaTag(systemImage: "flame.fill", text: text)
        }
    }
}

struct RecipeCommunityLikesTag: View {
    let count: Int
    var usesMaterial: Bool = false

    var body: some View {
        Group {
            if usesMaterial {
                RecipeMaterialMetaTag(systemImage: "heart.fill", text: "\(count)")
            } else {
                RecipeMetaTag(
                    systemImage: "heart.fill",
                    text: "\(count)",
                    tint: .red.opacity(0.85)
                )
            }
        }
        .accessibilityLabel(Text("accessibility.communityLikes \(count)"))
    }
}

struct RecipeUserRatingView: View {
    let rating: Int
    var isInteractive: Bool = false
    var starSize: Font?
    var onSelect: ((Int) -> Void)?

    private var resolvedStarSize: Font {
        starSize ?? (isInteractive ? .title3 : .caption)
    }

    var body: some View {
        HStack(spacing: isInteractive ? 3 : 6) {
            ForEach(1...5, id: \.self) { value in
                Button {
                    guard isInteractive else { return }
                    onSelect?(value == rating ? 0 : value)
                } label: {
                    Image(systemName: value <= rating ? "star.fill" : "star")
                        .font(resolvedStarSize)
                        .foregroundStyle(value <= rating ? AppTheme.warmFill : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(!isInteractive)
                .accessibilityLabel(Text("accessibility.ratingStar \(value)"))
            }
        }
        .accessibilityElement(children: isInteractive ? .contain : .ignore)
        .accessibilityLabel(
            rating > 0
                ? Text("accessibility.userRating \(rating)")
                : Text("accessibility.userRating.none")
        )
    }
}

struct RecipeMetaRow: View {
    let recipe: Recipe
    var showsCookTime: Bool = true

    var body: some View {
        HStack(spacing: 6) {
            if showsCookTime {
                RecipeCookTimeTag(minutes: recipe.cookTimeMinutes)
            }
            Spacer(minLength: 0)
        }
    }
}

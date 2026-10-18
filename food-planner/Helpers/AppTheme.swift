import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.11, green: 0.37, blue: 0.29)
    static let accentMuted = Color(red: 0.22, green: 0.48, blue: 0.40)
    static let warmFill = Color(red: 0.83, green: 0.47, blue: 0.23)
    static let success = Color(red: 0.18, green: 0.58, blue: 0.42)
    static let warning = Color(red: 0.82, green: 0.42, blue: 0.18)

    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.07, green: 0.22, blue: 0.20),
            Color(red: 0.12, green: 0.36, blue: 0.30),
            Color(red: 0.20, green: 0.45, blue: 0.34),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let instagramGradient = LinearGradient(
        colors: [
            Color(red: 0.51, green: 0.23, blue: 0.72),
            Color(red: 0.88, green: 0.19, blue: 0.42),
            Color(red: 0.96, green: 0.38, blue: 0.15),
            Color(red: 0.99, green: 0.75, blue: 0.18),
        ],
        startPoint: .topTrailing,
        endPoint: .bottomLeading
    )

    static let cardRadius: CGFloat = 16
    static let controlMinHeight: CGFloat = 52
    static let sectionSpacing: CGFloat = 24
    static let contentPadding: CGFloat = 16
    static let sectionRailSpacing: CGFloat = 12
    static let recipeCardImageAspect: CGFloat = 4.0 / 3.0
    static let recipeCardImageHeight: CGFloat = 168
    static let recipeHeroCardHeight: CGFloat = 220
    static let recipeRailCardWidth: CGFloat = 220
    static let tagChipRadius: CGFloat = 8

    static var warmHighlight: Color { warmFill }
    static var canvas: Color { Color(.systemGroupedBackground) }
    static var card: Color { Color(.secondarySystemGroupedBackground) }
    static var elevated: Color { Color(.systemBackground) }
    static var tagChipFill: Color { accent.opacity(0.08) }
    static var cardShadow: Color { Color.black.opacity(0.08) }

    static func accent(for colorScheme: ColorScheme, highContrast: Bool) -> Color {
        if highContrast {
            return colorScheme == .dark
                ? Color(red: 0.45, green: 0.88, blue: 0.72)
                : Color(red: 0.05, green: 0.28, blue: 0.20)
        }
        return accent
    }
}

struct AppSectionCard<Content: View>: View {
    var padding: CGFloat = AppTheme.contentPadding
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
    }
}

struct AppSectionHeader: View {
    let title: LocalizedStringKey
    var systemImage: String?
    var fillsWidth: Bool = true

    var body: some View {
        HStack(spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.accent.opacity(0.12), in: Circle())
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
            if fillsWidth {
                Spacer(minLength: 0)
            }
        }
    }
}

struct MotionSafeSymbolModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var kind: Kind

    enum Kind {
        case pulse
        case variableColor
        case bounce
    }

    func body(content: Content) -> some View {
        Group {
            if reduceMotion {
                content
            } else {
                switch kind {
                case .pulse:
                    content.symbolEffect(.pulse, options: .repeating.speed(0.4))
                case .variableColor:
                    content.symbolEffect(.variableColor.iterative, options: .repeating)
                case .bounce:
                    content.symbolEffect(.bounce)
                }
            }
        }
    }
}

extension View {
    func motionSafeSymbolEffect(_ kind: MotionSafeSymbolModifier.Kind) -> some View {
        modifier(MotionSafeSymbolModifier(kind: kind))
    }

    func appScreenBackground() -> some View {
        background(AppTheme.canvas)
    }
}

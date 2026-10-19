import SwiftUI
import UIKit

enum AppTheme {
    /// Мягкая оранжевая заливка для иконок и чипов (как у приёмов пищи в дне)
    static let accentSoft = Color(uiColor: UIColor { traits in
        let orange = UIColor(red: 255 / 255, green: 149 / 255, blue: 0 / 255, alpha: 1)
        if traits.userInterfaceStyle == .dark {
            return orange.withAlphaComponent(0.14)
        }
        return UIColor(red: 1.0, green: 0.93, blue: 0.86, alpha: 1)
    })
    /// Яркий оранжевый для текста, иконок и tint
    static let accent = Color(red: 255 / 255, green: 149 / 255, blue: 0 / 255)
    static let accentMuted = Color(red: 255 / 255, green: 170 / 255, blue: 50 / 255)
    static let warmFill = Color(red: 0.83, green: 0.47, blue: 0.23)
    static let success = Color(red: 0.18, green: 0.58, blue: 0.42)
    static let warning = Color(red: 0.82, green: 0.42, blue: 0.18)

    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.55, green: 0.28, blue: 0.02),
            Color(red: 0.95, green: 0.48, blue: 0.05),
            Color(red: 255 / 255, green: 210 / 255, blue: 170 / 255),
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
    static let cardPadding: CGFloat = 8
    /// Nested shape radius = outer radius − padding (Apple concentric corners).
    static var nestedCardRadius: CGFloat { max(cardRadius - cardPadding, 4) }
    static let controlMinHeight: CGFloat = 52
    static let sectionSpacing: CGFloat = 24
    static let contentPadding: CGFloat = 16
    static let sectionRailSpacing: CGFloat = 12
    static let recipeCardImageAspect: CGFloat = 4.0 / 3.0
    static let recipeCardImageHeight: CGFloat = 168
    static let recipeCardCompactImageHeight: CGFloat = 128
    static let recipeHeroCardHeight: CGFloat = 220
    static let recipeRailCardWidth: CGFloat = 220
    static let tagChipRadius: CGFloat = 8

    static var warmHighlight: Color { warmFill }
    /// Page / grouped canvas (base in Dark Mode).
    static var canvas: Color { Color(.systemGroupedBackground) }
    /// Primary cards on the canvas.
    static var card: Color { Color(.secondarySystemGroupedBackground) }
    /// Same elevation as cards — use for surfaces that must lift off the canvas.
    static var elevated: Color { Color(.secondarySystemGroupedBackground) }
    /// Nested chips / fills inside elevated cards.
    static var nestedFill: Color { Color(.tertiarySystemGroupedBackground) }
    static var tagChipFill: Color { accentSoft }
    static var cardShadow: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.black.withAlphaComponent(0.45)
                : UIColor.black.withAlphaComponent(0.08)
        })
    }

    static func accent(for colorScheme: ColorScheme, highContrast: Bool) -> Color {
        if highContrast {
            return colorScheme == .dark
                ? Color(red: 1.0, green: 0.72, blue: 0.35)
                : Color(red: 0.78, green: 0.38, blue: 0.0)
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

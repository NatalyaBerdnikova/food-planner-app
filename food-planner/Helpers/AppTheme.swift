import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.06, green: 0.33, blue: 0.45)
    static let accentSoft = Color(red: 0.10, green: 0.45, blue: 0.52)
    static let warmFill = Color(red: 0.93, green: 0.55, blue: 0.28)
    static let success = Color(red: 0.20, green: 0.62, blue: 0.45)
    static let warning = Color(red: 0.85, green: 0.45, blue: 0.20)

    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.04, green: 0.22, blue: 0.32),
            Color(red: 0.08, green: 0.40, blue: 0.46),
            Color(red: 0.18, green: 0.52, blue: 0.48),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardRadius: CGFloat = 20
    static let controlMinHeight: CGFloat = 52

    static var warmHighlight: Color { warmFill }

    static func accent(for colorScheme: ColorScheme, highContrast: Bool) -> Color {
        if highContrast {
            return colorScheme == .dark
                ? Color(red: 0.45, green: 0.82, blue: 0.92)
                : Color(red: 0.02, green: 0.22, blue: 0.32)
        }
        return accent
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
}

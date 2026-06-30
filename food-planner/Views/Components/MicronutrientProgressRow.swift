import SwiftUI

struct MicronutrientProgressRow: View {
    let kind: MicronutrientKind
    let actual: Double

    private var target: Double { kind.dailyTarget }

    var body: some View {
        let status = NutritionTargetStatus.from(actual: actual, target: target)

        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(kind.displayName)
                    .font(.subheadline)
                Spacer(minLength: 12)
                Text(valueLabel)
                    .font(.caption)
                    .foregroundStyle(status?.color ?? .secondary)
                    .multilineTextAlignment(.trailing)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                    Capsule()
                        .fill(status?.color ?? .accentColor)
                        .frame(width: geometry.size.width * progressFraction)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 4)
    }

    private var valueLabel: String {
        let unit = String(localized: String.LocalizationValue(kind.unitLocalizationKey))
        let percent = target > 0 ? Int((actual / target * 100).rounded()) : 0
        return "\(formatted(actual)) / \(formatted(target)) \(unit) · \(percent)%"
    }

    private var progressFraction: CGFloat {
        guard target > 0 else { return 0 }
        return CGFloat(min(actual / target, 1))
    }

    private func formatted(_ value: Double) -> String {
        if value >= 100 {
            return String(format: "%.0f", value)
        }
        return value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}

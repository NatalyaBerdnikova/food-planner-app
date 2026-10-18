import SwiftUI

struct NutritionTargetProgressView: View {
    let actual: DailyNutrition
    let target: DailyNutrition
    var macroLabelStyle: MacroLabelStyle = .full
    var embedded: Bool = false

    @AppStorage(MacroDisplaySettings.showFractionsKey) private var showMacroFractions =
        MacroDisplaySettings.showFractionsDefault

    var body: some View {
        Group {
            if embedded {
                content
            } else {
                content
                    .padding(AppTheme.contentPadding)
                    .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("home.targetProgress")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            progressRow(
                title: macroLabelStyle.kcalTitle,
                actual: actual.calories,
                target: target.calories
            )
            progressRow(
                title: macroLabelStyle.proteinTitle,
                actual: actual.protein,
                target: target.protein
            )
            progressRow(
                title: macroLabelStyle.fatTitle,
                actual: actual.fat,
                target: target.fat
            )
            progressRow(
                title: macroLabelStyle.carbsTitle,
                actual: actual.carbs,
                target: target.carbs
            )
        }
    }

    private func progressRow(
        title: LocalizedStringResource,
        actual: Double,
        target: Double
    ) -> some View {
        let status = NutritionTargetStatus.from(actual: actual, target: target)

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                Spacer()
                Text("\(formatted(actual)) / \(formatted(target))")
                    .font(.caption)
                    .foregroundStyle(status?.color ?? .secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                    Capsule()
                        .fill(status?.color ?? .accentColor)
                        .frame(width: geometry.size.width * progressWidth(actual: actual, target: target))
                }
            }
            .frame(height: 6)
        }
    }

    private func progressWidth(actual: Double, target: Double) -> CGFloat {
        guard target > 0 else { return 0 }
        return CGFloat(min(actual / target, 1))
    }

    private func formatted(_ value: Double) -> String {
        MacroDisplaySettings.format(value, showFractions: showMacroFractions)
    }
}

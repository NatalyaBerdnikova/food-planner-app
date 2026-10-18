import SwiftUI

struct NutritionSummaryView: View {
    let nutrition: DailyNutrition
    var target: DailyNutrition?
    var title: LocalizedStringResource = "nutrition.title.day"
    var embedded: Bool = false
    var macroLabelStyle: MacroLabelStyle = .compact

    var body: some View {
        Group {
            if embedded {
                content
            } else {
                content
                    .padding(AppTheme.cardPadding)
                    .background(
                        AppTheme.elevated,
                        in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var content: some View {
        HStack(spacing: AppTheme.cardPadding) {
            macroChip(title: macroLabelStyle.kcalTitle, value: nutrition.calories, target: target?.calories)
            macroChip(title: macroLabelStyle.proteinTitle, value: nutrition.protein, target: target?.protein)
            macroChip(title: macroLabelStyle.fatTitle, value: nutrition.fat, target: target?.fat)
            macroChip(title: macroLabelStyle.carbsTitle, value: nutrition.carbs, target: target?.carbs)
        }
    }

    private func macroChip(title: LocalizedStringResource, value: Double, target: Double?) -> some View {
        let status = target.flatMap { NutritionTargetStatus.from(actual: value, target: $0) }

        return VStack(spacing: 2) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(formatted(value))
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(status?.color ?? .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            AppTheme.canvas,
            in: RoundedRectangle(cornerRadius: AppTheme.nestedCardRadius, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }

    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}

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
                    .padding(AppTheme.contentPadding)
                    .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var content: some View {
        HStack(spacing: 8) {
            macroChip(title: macroLabelStyle.kcalTitle, value: nutrition.calories, target: target?.calories)
            macroChip(title: macroLabelStyle.proteinTitle, value: nutrition.protein, target: target?.protein)
            macroChip(title: macroLabelStyle.fatTitle, value: nutrition.fat, target: target?.fat)
            macroChip(title: macroLabelStyle.carbsTitle, value: nutrition.carbs, target: target?.carbs)
        }
    }

    private func macroChip(title: LocalizedStringResource, value: Double, target: Double?) -> some View {
        let status = target.flatMap { NutritionTargetStatus.from(actual: value, target: $0) }

        return VStack(spacing: 4) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            Text(formatted(value))
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(status?.color ?? .primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .background(AppTheme.canvas, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}

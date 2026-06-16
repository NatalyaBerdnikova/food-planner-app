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
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                macroChip(title: macroLabelStyle.kcalTitle, value: nutrition.calories, target: target?.calories)
                macroChip(title: macroLabelStyle.proteinTitle, value: nutrition.protein, target: target?.protein)
                macroChip(title: macroLabelStyle.fatTitle, value: nutrition.fat, target: target?.fat)
                macroChip(title: macroLabelStyle.carbsTitle, value: nutrition.carbs, target: target?.carbs)
            }
        }
    }

    private func macroChip(title: LocalizedStringResource, value: Double, target: Double?) -> some View {
        let status = target.flatMap { NutritionTargetStatus.from(actual: value, target: $0) }

        return VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(formatted(value))
                .font(.headline)
                .foregroundStyle(status?.color ?? .primary)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}

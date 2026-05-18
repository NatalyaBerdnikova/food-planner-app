import SwiftUI

struct NutritionSummaryView: View {
    let nutrition: DailyNutrition
    var title: LocalizedStringResource = "nutrition.title.day"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                macroChip(title: "nutrition.macro.kcal", value: nutrition.calories)
                macroChip(title: "nutrition.macro.protein", value: nutrition.protein)
                macroChip(title: "nutrition.macro.fat", value: nutrition.fat)
                macroChip(title: "nutrition.macro.carbs", value: nutrition.carbs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func macroChip(title: LocalizedStringResource, value: Double) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(formatted(value))
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}

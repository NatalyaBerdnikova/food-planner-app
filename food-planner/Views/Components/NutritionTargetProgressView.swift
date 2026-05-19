import SwiftUI

struct NutritionTargetProgressView: View {
    let actual: DailyNutrition
    let target: DailyNutrition

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("home.targetProgress")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            progressRow(
                title: "nutrition.macro.kcal",
                actual: actual.calories,
                target: target.calories
            )
            progressRow(
                title: "nutrition.macro.protein",
                actual: actual.protein,
                target: target.protein
            )
            progressRow(
                title: "nutrition.macro.fat",
                actual: actual.fat,
                target: target.fat
            )
            progressRow(
                title: "nutrition.macro.carbs",
                actual: actual.carbs,
                target: target.carbs
            )
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func progressRow(
        title: LocalizedStringResource,
        actual: Double,
        target: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                Spacer()
                Text("\(formatted(actual)) / \(formatted(target))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                    Capsule()
                        .fill(progressColor(actual: actual, target: target))
                        .frame(width: geometry.size.width * min(progress(actual: actual, target: target), 1))
                }
            }
            .frame(height: 6)
        }
    }

    private func progress(actual: Double, target: Double) -> CGFloat {
        guard target > 0 else { return 0 }
        return CGFloat(min(actual / target, 1.2))
    }

    private func progressColor(actual: Double, target: Double) -> Color {
        guard target > 0 else { return .accentColor }
        let ratio = actual / target
        if ratio > 1.1 { return .orange }
        return .accentColor
    }

    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}

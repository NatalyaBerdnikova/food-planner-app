import SwiftUI

struct MealPlanTargetsCard: View {
    let target: DailyNutrition
    var micronutrientFocus: [MicronutrientKind] = []
    var titleKey: LocalizedStringKey = "onboarding.dayPreview.personalized.title"
    var subtitleKey: LocalizedStringKey = "onboarding.dayPreview.personalized.subtitle"

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(titleKey)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitleKey)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                parameterChip(
                    title: "nutrition.macro.kcal.full",
                    value: "\(Int(target.calories.rounded()))"
                )
                parameterChip(
                    title: "nutrition.macro.protein.full",
                    value: "\(Int(target.protein.rounded()))g"
                )
                parameterChip(
                    title: "nutrition.macro.fat.full",
                    value: "\(Int(target.fat.rounded()))g"
                )
                parameterChip(
                    title: "nutrition.macro.carbs.full",
                    value: "\(Int(target.carbs.rounded()))g"
                )
            }

            if !micronutrientFocus.isEmpty {
                Text(
                    micronutrientFocus
                        .prefix(4)
                        .map(\.displayName)
                        .joined(separator: " · ")
                )
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .fill(AppTheme.accent.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                        .strokeBorder(AppTheme.accent.opacity(0.18), lineWidth: 1)
                }
        }
        .accessibilityElement(children: .combine)
    }

    private func parameterChip(title: LocalizedStringKey, value: String) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .background(
            AppTheme.elevated.opacity(0.92),
            in: RoundedRectangle(cornerRadius: AppTheme.nestedCardRadius, style: .continuous)
        )
    }
}

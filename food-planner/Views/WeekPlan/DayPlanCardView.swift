import SwiftUI

struct DayPlanCardView: View {
    let dayPlan: DayPlan
    let isSelected: Bool
    let onAddMeal: () -> Void

    private var dayTitle: String {
        dayPlan.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(dayPlan.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dayTitle)
                        .font(.headline)
                    if isToday {
                        Text("weekPlan.today")
                            .font(.caption)
                            .foregroundStyle(.tint)
                    }
                }
                Spacer()
            }

            if dayPlan.meals.isEmpty {
                Text("weekPlan.noMeals")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sortedMeals) { meal in
                    MealRowView(meal: meal)
                }
            }

            Button(action: onAddMeal) {
                Label("common.add", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.medium))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: borderWidth)
        }
    }

    private var borderWidth: CGFloat {
        isSelected || isToday ? 2 : 0
    }

    private var borderColor: Color {
        if isSelected { return .accentColor }
        if isToday { return .accentColor.opacity(0.5) }
        return .clear
    }

    private var sortedMeals: [Meal] {
        dayPlan.meals.sorted { lhs, rhs in
            lhs.mealType.rawValue < rhs.mealType.rawValue
        }
    }
}

struct MealRowView: View {
    let meal: Meal

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .foregroundStyle(.tint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(meal.mealType.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(meal.recipe?.name ?? String(localized: "meal.noRecipe"))
                    .font(.subheadline)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        switch meal.mealType {
        case .breakfast: "sunrise.fill"
        case .lunch: "sun.max.fill"
        case .dinner: "moon.stars.fill"
        case .snack: "leaf.fill"
        }
    }
}

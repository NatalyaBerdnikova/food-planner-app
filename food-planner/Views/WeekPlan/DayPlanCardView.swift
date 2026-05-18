import SwiftUI

struct DayPlanCardView: View {
    let dayPlan: DayPlan
    let isExpanded: Bool
    let onToggle: () -> Void
    let onAddMeal: () -> Void

    private var dayTitle: String {
        dayPlan.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(dayPlan.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onToggle) {
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
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
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
        }
        .padding()
        .frame(width: 280, alignment: .topLeading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            if isToday {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.accentColor, lineWidth: 2)
            }
        }
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

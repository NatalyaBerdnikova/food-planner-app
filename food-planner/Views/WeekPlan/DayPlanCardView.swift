import SwiftUI

struct DayPlanCardView: View {
    let dayPlan: DayPlan
    let isSelected: Bool
    let onAddMeal: () -> Void

    private let dayMealTypes: [MealType] = [.breakfast, .lunch, .dinner, .snack]

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

            VStack(spacing: 4) {
                ForEach(dayMealTypes, id: \.self) { type in
                    MealRowView(mealType: type, meal: meal(for: type))
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

    private func meal(for type: MealType) -> Meal? {
        dayPlan.meals.first { $0.mealType == type }
    }

    private var borderWidth: CGFloat {
        isSelected || isToday ? 2 : 0
    }

    private var borderColor: Color {
        if isSelected { return .accentColor }
        if isToday { return .accentColor.opacity(0.5) }
        return .clear
    }
}

struct MealRowView: View {
    let mealType: MealType
    let meal: Meal?

    init(meal: Meal) {
        self.mealType = meal.mealType
        self.meal = meal
    }

    init(mealType: MealType, meal: Meal?) {
        self.mealType = mealType
        self.meal = meal
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .foregroundStyle(.tint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(mealTypeLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(meal?.recipe?.name ?? String(localized: "home.notPlanned"))
                    .font(.subheadline)
                    .lineLimit(1)
                    .foregroundStyle(meal?.recipe == nil ? .secondary : .primary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var mealTypeLabel: LocalizedStringResource {
        mealType == .snack ? "filter.other" : mealType.displayName
    }

    private var iconName: String {
        switch mealType {
        case .breakfast: "sunrise.fill"
        case .lunch: "sun.max.fill"
        case .dinner: "moon.stars.fill"
        case .snack: "ellipsis.circle.fill"
        }
    }
}

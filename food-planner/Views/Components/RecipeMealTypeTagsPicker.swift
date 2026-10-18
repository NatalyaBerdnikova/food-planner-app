import SwiftUI

struct RecipeMealTypeTagsPicker: View {
    @Binding var selected: Set<MealType>

    private let options: [(MealType, LocalizedStringResource)] = [
        (.breakfast, "mealType.breakfast"),
        (.lunch, "mealType.lunch"),
        (.dinner, "mealType.dinner"),
        (.snack, "filter.other"),
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.0) { mealType, title in
                    let isOn = selected.contains(mealType)
                    Button {
                        if isOn {
                            selected.remove(mealType)
                        } else {
                            selected.insert(mealType)
                        }
                    } label: {
                        Text(title)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isOn ? Color.accentColor : Color(.tertiarySystemFill))
                            .foregroundStyle(isOn ? Color.white : Color.primary)
                            .clipShape(Capsule())
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }
}

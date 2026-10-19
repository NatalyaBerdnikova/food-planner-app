import SwiftUI

struct WeekRangeSwitcher: View {
    @Binding var weekStart: Date

    var body: some View {
        HStack {
            Button {
                shiftWeek(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("accessibility.previousWeek")

            Spacer()

            Text(weekRangeTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer()

            Button {
                shiftWeek(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("accessibility.nextWeek")
        }
        .padding(.horizontal, 4)
        .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
    }

    private var weekRangeTitle: String {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: calendar.startOfWeek(for: weekStart))
        guard let endDate = calendar.date(byAdding: .day, value: 6, to: start) else {
            return start.formatted(.dateTime.day().month(.abbreviated))
        }
        let startText = start.formatted(.dateTime.day().month(.abbreviated))
        let endText = endDate.formatted(.dateTime.day().month(.abbreviated))
        return "\(startText) - \(endText)"
    }

    private func shiftWeek(by offset: Int) {
        guard let newStart = Calendar.current.date(byAdding: .weekOfYear, value: offset, to: weekStart) else {
            return
        }
        weekStart = Calendar.current.startOfWeek(for: newStart)
    }
}

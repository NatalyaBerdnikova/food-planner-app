import Foundation

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? startOfDay(for: date)
    }

    func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        isDate(lhs, inSameDayAs: rhs)
    }

    func weekDates(startingFrom weekStart: Date, count: Int = 7) -> [Date] {
        (0..<count).compactMap { offset in
            self.date(byAdding: .day, value: offset, to: weekStart)
        }
    }
}

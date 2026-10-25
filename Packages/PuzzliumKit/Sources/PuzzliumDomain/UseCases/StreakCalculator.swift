import Foundation

/// Consecutive days with at least one completed puzzle, ending today or yesterday.
public struct StreakCalculator: Sendable {
    public init() {}

    public func currentStreak(completionDates: [Date], today: Date, calendar: Calendar = .current) -> Int {
        let days = Set(completionDates.map { calendar.startOfDay(for: $0) })
        let todayStart = calendar.startOfDay(for: today)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: todayStart) else { return 0 }

        var cursor: Date
        if days.contains(todayStart) {
            cursor = todayStart
        } else if days.contains(yesterday) {
            cursor = yesterday
        } else {
            return 0
        }

        var streak = 0
        while days.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }
}

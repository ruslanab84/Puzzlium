import Foundation

/// Picks the same daily puzzle for everyone on a given calendar day, without a server.
public struct DailyPuzzleSelector: Sendable {
    private let referenceDate: Date

    public init(referenceDate: Date = Date(timeIntervalSince1970: 1_704_067_200)) { // 2024-01-01 UTC
        self.referenceDate = referenceDate
    }

    public func puzzle(for date: Date, in catalog: [Puzzle], calendar: Calendar = .current) -> Puzzle? {
        guard !catalog.isEmpty else { return nil }
        let ordered = catalog.sorted { $0.id < $1.id }
        let start = calendar.startOfDay(for: referenceDate)
        let day = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: start, to: day).day ?? 0
        let index = ((days % ordered.count) + ordered.count) % ordered.count
        return ordered[index]
    }
}

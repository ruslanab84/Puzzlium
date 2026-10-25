import Foundation

public struct PuzzleEntry: Identifiable, Hashable, Sendable {
    public enum Status: Hashable, Sendable {
        case notStarted
        case inProgress(fraction: Double)
        case completed
    }

    public let puzzle: Puzzle
    public let status: Status
    public let progress: PuzzleProgress?

    public init(puzzle: Puzzle, status: Status, progress: PuzzleProgress?) {
        self.puzzle = puzzle
        self.status = status
        self.progress = progress
    }

    public var id: String { puzzle.id }
}

public struct HomeFeed: Sendable, Equatable {
    public let daily: Puzzle?
    public let dailyProgress: PuzzleProgress?
    public let continueItems: [PuzzleEntry]
    public let newArrivals: [Puzzle]
    public let streak: Int

    public init(
        daily: Puzzle?,
        dailyProgress: PuzzleProgress?,
        continueItems: [PuzzleEntry],
        newArrivals: [Puzzle],
        streak: Int
    ) {
        self.daily = daily
        self.dailyProgress = dailyProgress
        self.continueItems = continueItems
        self.newArrivals = newArrivals
        self.streak = streak
    }
}

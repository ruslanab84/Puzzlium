import Foundation

/// A themed series of puzzles played in order, with growing piece counts.
/// Finishing every level of a chapter collects that chapter's postcard.
public struct PuzzleEvent: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let chapters: [EventChapter]

    public init(id: String, title: String, chapters: [EventChapter]) {
        self.id = id
        self.title = title
        self.chapters = chapters
    }

    /// Every level in play order.
    public var levels: [EventLevel] { chapters.flatMap(\.levels) }
}

public struct EventChapter: Identifiable, Hashable, Sendable {
    public let id: String
    public let postcardTitle: String
    public let postcard: PuzzleImageSource
    public let levels: [EventLevel]

    public init(id: String, postcardTitle: String, postcard: PuzzleImageSource, levels: [EventLevel]) {
        self.id = id
        self.postcardTitle = postcardTitle
        self.postcard = postcard
        self.levels = levels
    }
}

/// One level: a puzzle that exists only inside the event, so its progress never mixes with free play.
public struct EventLevel: Identifiable, Hashable, Sendable {
    public let puzzle: Puzzle
    public let pieceCount: PieceCount

    public init(puzzle: Puzzle, pieceCount: PieceCount) {
        self.puzzle = puzzle
        self.pieceCount = pieceCount
    }

    public var id: String { puzzle.id }
}

public enum LevelStatus: Hashable, Sendable {
    case locked
    case available
    case inProgress(fraction: Double)
    case completed
}

/// Event state derived from saved puzzle progress; nothing extra is persisted.
public struct EventProgress: Equatable, Sendable {
    public let statuses: [String: LevelStatus]
    /// Chapters whose postcard is collected.
    public let collected: Set<String>
    public let completedCount: Int
    public let totalCount: Int

    public init(statuses: [String: LevelStatus], collected: Set<String>, completedCount: Int, totalCount: Int) {
        self.statuses = statuses
        self.collected = collected
        self.completedCount = completedCount
        self.totalCount = totalCount
    }

    public func status(of level: EventLevel) -> LevelStatus {
        statuses[level.id] ?? .locked
    }

    public var isFinished: Bool { totalCount > 0 && completedCount == totalCount }
}

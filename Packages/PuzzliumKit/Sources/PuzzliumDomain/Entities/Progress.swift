import Foundation

/// Saved state of one puzzle. `snapshot` is opaque engine state (the Domain does not interpret it).
public struct PuzzleProgress: Identifiable, Hashable, Codable, Sendable {
    public let puzzleID: String
    public var pieceCount: PieceCount
    public var placedCount: Int
    public var rotationEnabled: Bool
    public var elapsed: TimeInterval
    public var isCompleted: Bool
    public var updatedAt: Date
    /// Date of the most recent completion, kept even when the puzzle is replayed.
    public var completedAt: Date?
    public var snapshot: Data

    public init(
        puzzleID: String,
        pieceCount: PieceCount,
        placedCount: Int,
        rotationEnabled: Bool,
        elapsed: TimeInterval,
        isCompleted: Bool,
        updatedAt: Date,
        completedAt: Date? = nil,
        snapshot: Data
    ) {
        self.puzzleID = puzzleID
        self.pieceCount = pieceCount
        self.placedCount = placedCount
        self.rotationEnabled = rotationEnabled
        self.elapsed = elapsed
        self.isCompleted = isCompleted
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.snapshot = snapshot
    }

    public var id: String { puzzleID }

    public var fraction: Double {
        guard pieceCount.rawValue > 0 else { return 0 }
        return min(1, Double(placedCount) / Double(pieceCount.rawValue))
    }

    /// Started, not finished, and worth showing in "Continue".
    public var isInProgress: Bool { !isCompleted && placedCount > 0 }
}

public struct PuzzleCompletion: Hashable, Sendable {
    public let puzzleID: String
    public let pieceCount: PieceCount
    public let duration: TimeInterval
    public let date: Date

    public init(puzzleID: String, pieceCount: PieceCount, duration: TimeInterval, date: Date) {
        self.puzzleID = puzzleID
        self.pieceCount = pieceCount
        self.duration = duration
        self.date = date
    }
}

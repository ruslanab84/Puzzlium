import Foundation
import PuzzliumDomain
import SwiftData

@Model
final class ProgressRecord {
    @Attribute(.unique) var puzzleID: String
    var pieceCount: Int
    var placedCount: Int
    var rotationEnabled: Bool
    var elapsed: Double
    var isCompleted: Bool
    var updatedAt: Date
    var completedAt: Date?
    /// Engine snapshot; small (≈2 KB for 400 pieces) but kept out of the row when large.
    @Attribute(.externalStorage) var snapshot: Data

    init(_ progress: PuzzleProgress) {
        puzzleID = progress.puzzleID
        pieceCount = progress.pieceCount.rawValue
        placedCount = progress.placedCount
        rotationEnabled = progress.rotationEnabled
        elapsed = progress.elapsed
        isCompleted = progress.isCompleted
        updatedAt = progress.updatedAt
        completedAt = progress.completedAt
        snapshot = progress.snapshot
    }

    func update(from progress: PuzzleProgress) {
        pieceCount = progress.pieceCount.rawValue
        placedCount = progress.placedCount
        rotationEnabled = progress.rotationEnabled
        elapsed = progress.elapsed
        isCompleted = progress.isCompleted
        updatedAt = progress.updatedAt
        completedAt = progress.completedAt ?? completedAt
        snapshot = progress.snapshot
    }

    var domain: PuzzleProgress {
        PuzzleProgress(
            puzzleID: puzzleID,
            pieceCount: PieceCount(rawValue: pieceCount) ?? .p64,
            placedCount: placedCount,
            rotationEnabled: rotationEnabled,
            elapsed: elapsed,
            isCompleted: isCompleted,
            updatedAt: updatedAt,
            completedAt: completedAt,
            snapshot: snapshot
        )
    }
}

@Model
final class CompletionRecord {
    var puzzleID: String
    var pieceCount: Int
    var duration: Double
    var date: Date

    init(_ completion: PuzzleCompletion) {
        puzzleID = completion.puzzleID
        pieceCount = completion.pieceCount.rawValue
        duration = completion.duration
        date = completion.date
    }
}

public enum PersistenceFactory {
    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([ProgressRecord.self, CompletionRecord.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

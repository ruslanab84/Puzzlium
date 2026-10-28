import Foundation

public protocol PuzzleRepository: Sendable {
    /// Offline-first: returns local data immediately; refreshes from network when stale.
    func catalog() async throws -> [Puzzle]
    /// Saves a player's photo (any image format) and returns the new puzzle made from it.
    func addPhoto(_ imageData: Data) async throws -> Puzzle
}

public protocol ProgressRepository: Sendable {
    func progress(for puzzleID: String) async throws -> PuzzleProgress?
    /// Sorted by `updatedAt`, newest first.
    func allProgress() async throws -> [PuzzleProgress]
    func save(_ progress: PuzzleProgress) async throws
    func recordCompletion(_ completion: PuzzleCompletion) async throws
    func completionDates() async throws -> [Date]
}

public protocol PreferencesRepository: Sendable {
    func load() -> GamePreferences
    func save(_ preferences: GamePreferences)
}

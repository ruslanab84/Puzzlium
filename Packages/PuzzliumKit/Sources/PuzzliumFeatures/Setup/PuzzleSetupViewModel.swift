import Foundation
import Observation
import PuzzliumDomain

@Observable
@MainActor
final class PuzzleSetupViewModel {
    let puzzle: Puzzle
    var pieceCount: PieceCount
    var rotationEnabled: Bool
    var table: TableSurface
    private(set) var savedProgress: PuzzleProgress?

    private let preferencesRepository: any PreferencesRepository
    private let progressRepository: any ProgressRepository
    private var preferences: GamePreferences

    init(puzzle: Puzzle, dependencies: FeatureDependencies) {
        self.puzzle = puzzle
        preferencesRepository = dependencies.preferences
        progressRepository = dependencies.progress
        let preferences = dependencies.preferences.load()
        self.preferences = preferences
        pieceCount = puzzle.pieceCounts.contains(preferences.pieceCount) ? preferences.pieceCount : puzzle.recommendedPieceCount
        rotationEnabled = preferences.rotationEnabled
        table = preferences.table
    }

    /// The saved game matches the current choices and will be resumed instead of restarted.
    var resumesSavedGame: Bool {
        guard let savedProgress, savedProgress.isInProgress else { return false }
        return savedProgress.pieceCount == pieceCount && savedProgress.rotationEnabled == rotationEnabled
    }

    func load() async {
        savedProgress = try? await progressRepository.progress(for: puzzle.id)
        if let savedProgress, savedProgress.isInProgress, puzzle.pieceCounts.contains(savedProgress.pieceCount) {
            pieceCount = savedProgress.pieceCount
            rotationEnabled = savedProgress.rotationEnabled
        }
    }

    func makeConfiguration() -> GameConfiguration {
        preferences.pieceCount = pieceCount
        preferences.rotationEnabled = rotationEnabled
        preferences.table = table
        preferencesRepository.save(preferences)
        return GameConfiguration(puzzle: puzzle, pieceCount: pieceCount, rotationEnabled: rotationEnabled, table: table)
    }
}

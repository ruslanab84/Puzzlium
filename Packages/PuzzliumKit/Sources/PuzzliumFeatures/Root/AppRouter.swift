import Observation
import PuzzliumDomain

/// App-wide navigation state. Setup is a sheet; the game is a full-screen cover presented
/// only after the sheet has finished dismissing (avoids stacked-modal glitches).
@Observable
@MainActor
final class AppRouter {
    enum Tab: Hashable {
        case today
        case library
        case myPuzzles
    }

    var selectedTab: Tab = .today
    var setupPuzzle: Puzzle?
    var activeGame: GameConfiguration?
    /// Bumped whenever progress may have changed, so lists reload.
    private(set) var contentVersion = 0

    private var pendingGame: GameConfiguration?

    func openSetup(for puzzle: Puzzle) {
        setupPuzzle = puzzle
    }

    func start(_ configuration: GameConfiguration) {
        pendingGame = configuration
        setupPuzzle = nil
    }

    /// Starts a game without the setup sheet (event levels have fixed options).
    func play(_ configuration: GameConfiguration) {
        activeGame = configuration
    }

    func setupDismissed() {
        guard let pendingGame else { return }
        self.pendingGame = nil
        activeGame = pendingGame
    }

    func closeGame(showLibrary: Bool = false) {
        activeGame = nil
        contentVersion += 1
        if showLibrary { selectedTab = .library }
    }
}

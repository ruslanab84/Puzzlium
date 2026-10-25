import CoreGraphics
import Foundation
import Observation
import PuzzliumCore
import PuzzliumDomain
import PuzzliumEngine
import SwiftUI

struct CompletionSummary: Equatable {
    let duration: TimeInterval
    let pieceCount: Int
    let streak: Int
}

@Observable
@MainActor
final class GameViewModel {
    enum Phase: Equatable {
        case loading
        case playing
        case completed(CompletionSummary)
        case failed
    }

    private enum GameError: Error {
        case renderingFailed
    }

    /// The dragged piece floats above the finger so it stays visible.
    static let liftOffset = CGSize(width: 0, height: -44)
    static let maxHints = 3

    let configuration: GameConfiguration

    private(set) var phase: Phase = .loading
    private(set) var board: BoardState?
    private(set) var sourceImage: CGImage?
    /// All placed pieces in one bitmap: the board draws a single image regardless of piece count.
    private(set) var compositeImage: CGImage?
    /// Outline of every slot, in unit coordinates (scaled by the board view).
    private(set) var slotOutline: Path?
    /// Changes only when a drag starts/ends, so the tray does not re-render on every finger move.
    private(set) var draggingPiece: Int?
    private(set) var dragLocation: CGPoint = .zero
    /// From finger to piece centre: `liftOffset` from the tray, the grab point for loose pieces.
    private(set) var dragOffset: CGSize = liftOffset
    private(set) var snapCount = 0
    private(set) var missCount = 0
    private(set) var showsPreview: Bool
    var trayFilter: TrayFilter = .all

    @ObservationIgnored private var layout: PuzzleLayout?
    @ObservationIgnored private var pieces: RenderedPieces?
    @ObservationIgnored private var compositor: BoardCompositor?
    @ObservationIgnored private var clockStartedAt: Date?
    @ObservationIgnored private var accumulated: TimeInterval = 0
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private var isFinishing = false

    private let dependencies: FeatureDependencies
    private let snapResolver = SnapResolver()

    init(configuration: GameConfiguration, dependencies: FeatureDependencies) {
        self.configuration = configuration
        self.dependencies = dependencies
        showsPreview = dependencies.preferences.load().showsPreview
    }

    // MARK: - Derived state

    var trayPieces: [Int] {
        guard let board, let layout else { return [] }
        return board.trayPieces(trayFilter, layout: layout)
    }

    func trayCount(_ filter: TrayFilter) -> Int {
        guard let board, let layout else { return 0 }
        return board.trayPieces(filter, layout: layout).count
    }

    var hintsLeft: Int { max(0, Self.maxHints - (board?.hintsUsed ?? 0)) }

    func elapsed(at date: Date) -> TimeInterval {
        accumulated + (clockStartedAt.map { max(0, date.timeIntervalSince($0)) } ?? 0)
    }

    func image(for piece: Int) -> CGImage? {
        guard let pieces, pieces.images.indices.contains(piece) else { return nil }
        return pieces.images[piece]
    }

    func rotation(of piece: Int) -> Int {
        board?.rotation(of: piece) ?? 0
    }

    /// On-screen size of a piece image when the board is `boardWidth` points wide.
    func pieceSize(_ piece: Int, boardWidth: CGFloat) -> CGSize? {
        guard let pieces, pieces.rects.indices.contains(piece), boardWidth > 0 else { return nil }
        let scale = boardWidth / pieces.boardPixelSize.width
        let rect = pieces.rects[piece]
        return CGSize(width: rect.width * scale, height: rect.height * scale)
    }

    // MARK: - Lifecycle

    func load() async {
        guard phase == .loading, board == nil else { return }
        let puzzle = configuration.puzzle
        let grid = GridSize.square(configuration.pieceCount.side)

        do {
            let restored = await restoredState(grid: grid)
            let state = restored ?? BoardState(
                grid: grid,
                seed: StableHash.seed(puzzle.id, String(configuration.pieceCount.rawValue)),
                rotationEnabled: configuration.rotationEnabled
            )
            let layout = PuzzleLayout.generate(grid: state.grid, seed: state.seed)
            let pixelSize = min(2048, max(1024, configuration.pieceCount.side * 80))
            let image = try await dependencies.images.image(for: puzzle.image, pixelSize: pixelSize)

            let rendered = await Task.detached(priority: .userInitiated) {
                PieceImageRenderer.render(source: image.cgImage, layout: layout)
            }.value
            guard let rendered, let compositor = BoardCompositor(pieces: rendered) else {
                throw GameError.renderingFailed
            }
            for piece in state.placed {
                compositor.draw(piece: piece)
            }

            self.layout = layout
            self.pieces = rendered
            self.compositor = compositor
            sourceImage = image.cgImage
            compositeImage = compositor.makeImage()
            slotOutline = Path(PieceGeometry(layout: layout, boardSize: CGSize(width: 1, height: 1)).slotsPath())
            accumulated = state.elapsed
            board = state
            phase = .playing
            startClock()

            let pieces = configuration.pieceCount.rawValue
            dependencies.analytics.track(
                restored == nil
                    ? .puzzleStarted(puzzleID: puzzle.id, pieces: pieces, rotation: configuration.rotationEnabled)
                    : .puzzleResumed(puzzleID: puzzle.id, pieces: pieces)
            )
        } catch {
            Log.game.error("Failed to load puzzle: \(String(describing: error), privacy: .public)")
            phase = .failed
        }
    }

    func retry() async {
        phase = .loading
        board = nil
        await load()
    }

    func pause() {
        guard phase == .playing else { return }
        stopClock()
        saveTask?.cancel()
        Task { await persist() }
    }

    func resume() {
        guard phase == .playing else { return }
        startClock()
    }

    /// Saves immediately; call before dismissing the game.
    func prepareToClose() async {
        guard phase == .playing else { return }
        stopClock()
        saveTask?.cancel()
        await persist()
    }

    // MARK: - Interaction

    var loosePieces: [LoosePiece] { board?.loose ?? [] }

    func drag(_ piece: Int, to location: CGPoint, offset: CGSize = liftOffset) {
        guard phase == .playing else { return }
        if draggingPiece != piece {
            draggingPiece = piece
            dragOffset = offset
        }
        dragLocation = location
    }

    func cancelDrag() {
        draggingPiece = nil
    }

    func endDrag(in boardFrame: CGRect) {
        guard let piece = draggingPiece else { return }
        draggingPiece = nil
        guard var state = board, let layout, boardFrame.width > 0 else { return }

        let center = CGPoint(
            x: dragLocation.x + dragOffset.width - boardFrame.minX,
            y: dragLocation.y + dragOffset.height - boardFrame.minY
        )
        let geometry = PieceGeometry(layout: layout, boardSize: boardFrame.size)
        let snaps = snapResolver.shouldSnap(piece: piece, droppedCenter: center, rotation: state.rotation(of: piece), geometry: geometry)

        if snaps, state.place(piece) {
            board = state
            didPlace(piece)
            return
        }
        // Like a real table: a miss stays where it was dropped; dropping off the board returns it to the tray.
        if CGRect(origin: .zero, size: boardFrame.size).contains(center) {
            state.drop(piece, at: CGPoint(x: center.x / boardFrame.width, y: center.y / boardFrame.height))
            missCount += 1
        } else {
            state.returnToTray(piece)
        }
        guard state != board else { return }
        board = state
        scheduleSave()
    }

    func rotate(_ piece: Int) {
        guard configuration.rotationEnabled, phase == .playing else { return }
        board?.rotate(piece)
    }

    func useHint() {
        guard hintsLeft > 0, var state = board, let layout else { return }
        guard let piece = state.trayPieces(trayFilter, layout: layout).first ?? state.tray.first ?? state.loose.first?.piece,
              state.forcePlace(piece, countsAsHint: true)
        else { return }
        board = state
        dependencies.analytics.track(.hintUsed(puzzleID: configuration.puzzle.id))
        didPlace(piece)
    }

    /// VoiceOver path: places the piece directly (drag-and-drop is not accessible).
    func placeAccessibly(_ piece: Int) {
        guard var state = board, state.forcePlace(piece, countsAsHint: false) else { return }
        board = state
        didPlace(piece)
    }

    func shuffleTray() {
        board?.shuffleTray(seed: UInt64.random(in: 0...UInt64.max))
    }

    func togglePreview() {
        showsPreview.toggle()
        var preferences = dependencies.preferences.load()
        preferences.showsPreview = showsPreview
        dependencies.preferences.save(preferences)
    }

    // MARK: - Private

    private func didPlace(_ piece: Int) {
        compositor?.draw(piece: piece)
        compositeImage = compositor?.makeImage()
        snapCount += 1
        if board?.isComplete == true {
            Task { await finish() }
        } else {
            scheduleSave()
        }
    }

    private func restoredState(grid: GridSize) async -> BoardState? {
        guard let saved = try? await dependencies.progress.progress(for: configuration.puzzle.id),
              saved.isInProgress,
              saved.pieceCount == configuration.pieceCount,
              saved.rotationEnabled == configuration.rotationEnabled,
              let state = try? BoardSnapshotCoder.decode(saved.snapshot),
              state.grid == grid
        else { return nil }
        return state
    }

    private func startClock() {
        if clockStartedAt == nil { clockStartedAt = dependencies.now() }
    }

    private func stopClock() {
        guard let started = clockStartedAt else { return }
        accumulated += max(0, dependencies.now().timeIntervalSince(started))
        clockStartedAt = nil
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            await self?.persist()
        }
    }

    private func persist() async {
        guard var state = board, !isFinishing else { return }
        state.elapsed = elapsed(at: dependencies.now())
        do {
            try await dependencies.progress.save(makeProgress(state, completedAt: nil))
        } catch {
            Log.game.error("Save failed: \(String(describing: error), privacy: .public)")
        }
    }

    private func finish() async {
        guard !isFinishing, var state = board else { return }
        isFinishing = true
        saveTask?.cancel()
        stopClock()
        state.elapsed = accumulated

        let now = dependencies.now()
        do {
            try await dependencies.progress.save(makeProgress(state, completedAt: now))
            try await dependencies.progress.recordCompletion(
                PuzzleCompletion(puzzleID: configuration.puzzle.id, pieceCount: configuration.pieceCount, duration: state.elapsed, date: now)
            )
        } catch {
            Log.game.error("Saving completion failed: \(String(describing: error), privacy: .public)")
        }
        let dates = (try? await dependencies.progress.completionDates()) ?? [now]
        let streak = StreakCalculator().currentStreak(completionDates: dates, today: now)
        dependencies.analytics.track(
            .puzzleCompleted(puzzleID: configuration.puzzle.id, pieces: state.totalCount, seconds: Int(state.elapsed))
        )

        // Let the finished picture sit for a moment before the summary.
        try? await Task.sleep(for: .milliseconds(700))
        phase = .completed(CompletionSummary(duration: state.elapsed, pieceCount: state.totalCount, streak: streak))
    }

    private func makeProgress(_ state: BoardState, completedAt: Date?) -> PuzzleProgress {
        PuzzleProgress(
            puzzleID: configuration.puzzle.id,
            pieceCount: configuration.pieceCount,
            placedCount: state.placedCount,
            rotationEnabled: configuration.rotationEnabled,
            elapsed: state.elapsed,
            isCompleted: state.isComplete,
            updatedAt: dependencies.now(),
            completedAt: completedAt,
            snapshot: (try? BoardSnapshotCoder.encode(state)) ?? Data()
        )
    }
}

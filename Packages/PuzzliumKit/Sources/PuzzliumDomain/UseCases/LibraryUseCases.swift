import Foundation

/// Catalog joined with local progress.
public struct GetLibraryUseCase: Sendable {
    private let puzzles: any PuzzleRepository
    private let progress: any ProgressRepository

    public init(puzzles: any PuzzleRepository, progress: any ProgressRepository) {
        self.puzzles = puzzles
        self.progress = progress
    }

    public func execute() async throws -> [PuzzleEntry] {
        async let catalog = puzzles.catalog()
        async let saved = progress.allProgress()
        return Self.merge(catalog: try await catalog, progress: try await saved)
    }

    static func merge(catalog: [Puzzle], progress: [PuzzleProgress]) -> [PuzzleEntry] {
        let byID = Dictionary(progress.map { ($0.puzzleID, $0) }, uniquingKeysWith: { first, _ in first })
        return catalog.map { puzzle in
            let saved = byID[puzzle.id]
            return PuzzleEntry(puzzle: puzzle, status: status(of: saved), progress: saved)
        }
    }

    static func status(of progress: PuzzleProgress?) -> PuzzleEntry.Status {
        guard let progress else { return .notStarted }
        if progress.isInProgress { return .inProgress(fraction: progress.fraction) }
        if progress.completedAt != nil || progress.isCompleted { return .completed }
        return .notStarted
    }
}

public struct GetHomeFeedUseCase: Sendable {
    private let puzzles: any PuzzleRepository
    private let progress: any ProgressRepository
    private let selector: DailyPuzzleSelector
    private let streakCalculator: StreakCalculator
    private let continueLimit: Int

    public init(
        puzzles: any PuzzleRepository,
        progress: any ProgressRepository,
        selector: DailyPuzzleSelector = DailyPuzzleSelector(),
        streakCalculator: StreakCalculator = StreakCalculator(),
        continueLimit: Int = 4
    ) {
        self.puzzles = puzzles
        self.progress = progress
        self.selector = selector
        self.streakCalculator = streakCalculator
        self.continueLimit = continueLimit
    }

    public func execute(now: Date, calendar: Calendar = .current) async throws -> HomeFeed {
        async let catalog = puzzles.catalog()
        async let saved = progress.allProgress()
        async let dates = progress.completionDates()
        let (puzzleList, progressList, completionDates) = try await (catalog, saved, dates)

        let items = GetLibraryUseCase.merge(catalog: puzzleList, progress: progressList)
        // Puzzles finished on an earlier day are never offered again; today's stays to show "Solved today".
        let solvedBefore = Set(progressList.filter { progress in
            guard progress.completedAt != nil || progress.isCompleted else { return false }
            return !(progress.completedAt.map { calendar.isDate($0, inSameDayAs: now) } ?? false)
        }.map(\.puzzleID))
        let daily = selector.puzzle(for: now, in: puzzleList, excluding: solvedBefore, calendar: calendar)
        let continueItems = items
            .filter { $0.progress?.isInProgress == true && $0.puzzle.id != daily?.id }
            .sorted { ($0.progress?.updatedAt ?? .distantPast) > ($1.progress?.updatedAt ?? .distantPast) }
            .prefix(continueLimit)

        return HomeFeed(
            daily: daily,
            dailyProgress: progressList.first { $0.puzzleID == daily?.id },
            continueItems: Array(continueItems),
            newArrivals: puzzleList.filter(\.isNew),
            streak: streakCalculator.currentStreak(completionDates: completionDates, today: now, calendar: calendar)
        )
    }
}

import Foundation
import Testing
@testable import PuzzliumDomain

private var utcCalendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}

private func day(_ value: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    return formatter.date(from: value)!
}

private func puzzle(_ id: String, isNew: Bool = false) -> Puzzle {
    Puzzle(id: id, title: id, category: .nature, image: .procedural(style: .lake, variant: 0), isNew: isNew)
}

private func progress(_ id: String, placed: Int, completed: Bool = false, updated: Date = .now, completedAt: Date? = nil) -> PuzzleProgress {
    PuzzleProgress(
        puzzleID: id,
        pieceCount: .p36,
        placedCount: placed,
        rotationEnabled: false,
        elapsed: 0,
        isCompleted: completed,
        updatedAt: updated,
        completedAt: completedAt,
        snapshot: Data()
    )
}

@Suite("StreakCalculator")
struct StreakCalculatorTests {
    let calculator = StreakCalculator()

    @Test func countsConsecutiveDaysEndingToday() {
        let dates = [day("2026-10-23"), day("2026-10-24"), day("2026-10-25"), day("2026-10-25")]
        #expect(calculator.currentStreak(completionDates: dates, today: day("2026-10-25"), calendar: utcCalendar) == 3)
    }

    @Test func yesterdayKeepsStreakAlive() {
        let dates = [day("2026-10-23"), day("2026-10-24")]
        #expect(calculator.currentStreak(completionDates: dates, today: day("2026-10-25"), calendar: utcCalendar) == 2)
    }

    @Test func gapResetsStreak() {
        let dates = [day("2026-10-20"), day("2026-10-23")]
        #expect(calculator.currentStreak(completionDates: dates, today: day("2026-10-25"), calendar: utcCalendar) == 0)
    }
}

@Suite("DailyPuzzleSelector")
struct DailyPuzzleSelectorTests {
    let catalog = (1...5).map { puzzle("p\($0)") }

    @Test func sameDaySamePuzzle() {
        let selector = DailyPuzzleSelector()
        let morning = day("2026-10-25")
        let evening = morning.addingTimeInterval(20 * 3600)
        #expect(selector.puzzle(for: morning, in: catalog, calendar: utcCalendar) == selector.puzzle(for: evening, in: catalog, calendar: utcCalendar))
    }

    @Test func nextDayRotates() {
        let selector = DailyPuzzleSelector()
        let today = selector.puzzle(for: day("2026-10-25"), in: catalog, calendar: utcCalendar)
        let tomorrow = selector.puzzle(for: day("2026-10-26"), in: catalog, calendar: utcCalendar)
        #expect(today != tomorrow)
    }

    @Test func emptyCatalog() {
        #expect(DailyPuzzleSelector().puzzle(for: .now, in: []) == nil)
    }

    @Test func skipsExcludedPuzzles() {
        let selector = DailyPuzzleSelector()
        let date = day("2026-10-25")
        let plain = selector.puzzle(for: date, in: catalog, calendar: utcCalendar)!
        let skipped = selector.puzzle(for: date, in: catalog, excluding: [plain.id], calendar: utcCalendar)
        #expect(skipped != nil && skipped != plain)
        #expect(selector.puzzle(for: date, in: catalog, excluding: Set(catalog.map(\.id)), calendar: utcCalendar) == plain)
    }
}

@Suite("GetLibraryUseCase")
struct LibraryMergeTests {
    @Test func mapsStatuses() {
        let items = GetLibraryUseCase.merge(
            catalog: [puzzle("a"), puzzle("b"), puzzle("c")],
            progress: [
                progress("a", placed: 10),
                progress("b", placed: 36, completed: true, completedAt: .now)
            ]
        )
        #expect(items[0].status == .inProgress(fraction: 10.0 / 36.0))
        #expect(items[1].status == .completed)
        #expect(items[2].status == .notStarted)
    }
}

private struct FakePuzzles: PuzzleRepository {
    let puzzles: [Puzzle]
    func catalog() async throws -> [Puzzle] { puzzles }
    func addPhoto(_ imageData: Data) async throws -> Puzzle { throw CancellationError() }
}

private actor FakeProgress: ProgressRepository {
    var items: [PuzzleProgress]
    var dates: [Date]

    init(items: [PuzzleProgress], dates: [Date]) {
        self.items = items
        self.dates = dates
    }

    func progress(for puzzleID: String) -> PuzzleProgress? { items.first { $0.puzzleID == puzzleID } }
    func allProgress() -> [PuzzleProgress] { items }
    func save(_ progress: PuzzleProgress) { items.append(progress) }
    func recordCompletion(_ completion: PuzzleCompletion) { dates.append(completion.date) }
    func completionDates() -> [Date] { dates }
}

@Suite("GetHomeFeedUseCase")
struct HomeFeedTests {
    @Test func buildsFeed() async throws {
        let today = day("2026-10-25")
        let catalog = [puzzle("a", isNew: true), puzzle("b"), puzzle("c")]
        let repo = FakeProgress(
            items: [
                progress("a", placed: 5, updated: today.addingTimeInterval(-100)),
                progress("b", placed: 7, updated: today.addingTimeInterval(-10)),
                progress("c", placed: 36, completed: true, completedAt: today)
            ],
            dates: [today]
        )
        let useCase = GetHomeFeedUseCase(puzzles: FakePuzzles(puzzles: catalog), progress: repo)
        let feed = try await useCase.execute(now: today, calendar: utcCalendar)

        #expect(feed.daily != nil)
        #expect(feed.streak == 1)
        #expect(feed.newArrivals.map(\.id) == ["a"])
        #expect(!feed.continueItems.contains { $0.puzzle.id == feed.daily?.id })
        #expect(feed.continueItems.allSatisfy { $0.progress?.isInProgress == true })
    }

    @Test func dailySkipsPuzzlesSolvedEarlierButKeepsTodays() async throws {
        let today = day("2026-10-25")
        let catalog = (1...5).map { puzzle("p\($0)") }
        let plain = DailyPuzzleSelector().puzzle(for: today, in: catalog, calendar: utcCalendar)!

        let solvedYesterday = FakeProgress(items: [progress(plain.id, placed: 36, completed: true, completedAt: today.addingTimeInterval(-86_400))], dates: [])
        let feed = try await GetHomeFeedUseCase(puzzles: FakePuzzles(puzzles: catalog), progress: solvedYesterday)
            .execute(now: today, calendar: utcCalendar)
        #expect(feed.daily != nil && feed.daily != plain)

        let solvedToday = FakeProgress(items: [progress(plain.id, placed: 36, completed: true, completedAt: today)], dates: [today])
        let todayFeed = try await GetHomeFeedUseCase(puzzles: FakePuzzles(puzzles: catalog), progress: solvedToday)
            .execute(now: today, calendar: utcCalendar)
        #expect(todayFeed.daily == plain)
    }
}

@Suite("GetEventProgressUseCase")
struct EventProgressTests {
    private let event = PuzzleEvent(
        id: "e",
        title: "e",
        chapters: [
            EventChapter(id: "c1", postcardTitle: "c1", postcard: .procedural(style: .lake, variant: 0), levels: [
                EventLevel(puzzle: puzzle("l1"), pieceCount: .p36),
                EventLevel(puzzle: puzzle("l2"), pieceCount: .p36)
            ]),
            EventChapter(id: "c2", postcardTitle: "c2", postcard: .procedural(style: .lake, variant: 0), levels: [
                EventLevel(puzzle: puzzle("l3"), pieceCount: .p36)
            ])
        ]
    )

    @Test func onlyFirstLevelOpensOnStart() {
        let result = GetEventProgressUseCase.evaluate(event, progress: [])
        #expect(result.status(of: event.levels[0]) == .available)
        #expect(result.status(of: event.levels[1]) == .locked)
        #expect(result.status(of: event.levels[2]) == .locked)
        #expect(result.collected.isEmpty)
    }

    @Test func finishingAChapterCollectsItsPostcardAndOpensTheNextLevel() {
        let result = GetEventProgressUseCase.evaluate(event, progress: [
            progress("l1", placed: 36, completed: true, completedAt: .now),
            progress("l2", placed: 36, completed: true, completedAt: .now)
        ])
        #expect(result.collected == ["c1"])
        #expect(result.status(of: event.levels[2]) == .available)
        #expect(result.completedCount == 2)
        #expect(!result.isFinished)
    }

    @Test func progressOnALockedLevelStaysLocked() {
        let result = GetEventProgressUseCase.evaluate(event, progress: [progress("l2", placed: 4)])
        #expect(result.status(of: event.levels[1]) == .locked)
    }
}

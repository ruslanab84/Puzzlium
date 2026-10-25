import Foundation

/// Joins an event with saved progress. Levels unlock strictly in order.
public struct GetEventProgressUseCase: Sendable {
    private let progress: any ProgressRepository

    public init(progress: any ProgressRepository) {
        self.progress = progress
    }

    public func execute(_ event: PuzzleEvent) async throws -> EventProgress {
        Self.evaluate(event, progress: try await progress.allProgress())
    }

    static func evaluate(_ event: PuzzleEvent, progress: [PuzzleProgress]) -> EventProgress {
        let byID = Dictionary(progress.map { ($0.puzzleID, $0) }, uniquingKeysWith: { first, _ in first })
        var statuses: [String: LevelStatus] = [:]
        var previousDone = true
        var completedCount = 0

        for level in event.levels {
            let status: LevelStatus = switch GetLibraryUseCase.status(of: byID[level.id]) {
            case .completed: .completed
            case let .inProgress(fraction): previousDone ? .inProgress(fraction: fraction) : .locked
            case .notStarted: previousDone ? .available : .locked
            }
            statuses[level.id] = status
            previousDone = status == .completed
            if previousDone { completedCount += 1 }
        }

        let collected = event.chapters
            .filter { chapter in chapter.levels.allSatisfy { statuses[$0.id] == .completed } }
            .map(\.id)

        return EventProgress(
            statuses: statuses,
            collected: Set(collected),
            completedCount: completedCount,
            totalCount: event.levels.count
        )
    }
}

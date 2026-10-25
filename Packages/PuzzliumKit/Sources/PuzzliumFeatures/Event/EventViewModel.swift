import Foundation
import Observation
import PuzzliumCore
import PuzzliumDomain

@Observable
@MainActor
final class EventViewModel {
    let event: PuzzleEvent
    private(set) var progress: EventProgress?
    /// Postcard shown in the reward sheet: freshly collected, or tapped in the collection.
    var shownPostcard: EventChapter?

    private let useCase: GetEventProgressUseCase
    private let preferences: any PreferencesRepository

    init(event: PuzzleEvent, dependencies: FeatureDependencies) {
        self.event = event
        useCase = GetEventProgressUseCase(progress: dependencies.progress)
        preferences = dependencies.preferences
    }

    func load() async {
        do {
            let fresh = try await useCase.execute(event)
            // Coming back from a level that finished a chapter: hand out its postcard.
            if let previous = progress,
               let chapter = event.chapters.last(where: { fresh.collected.contains($0.id) && !previous.collected.contains($0.id) }) {
                progress = fresh
                // Let the game cover finish dismissing; presenting mid-dismissal drops the sheet.
                try? await Task.sleep(for: .milliseconds(600))
                shownPostcard = chapter
                return
            }
            progress = fresh
        } catch {
            Log.ui.error("Event progress failed: \(String(describing: error), privacy: .public)")
        }
    }

    func status(of level: EventLevel) -> LevelStatus {
        progress?.status(of: level) ?? .locked
    }

    func isCollected(_ chapter: EventChapter) -> Bool {
        progress?.collected.contains(chapter.id) == true
    }

    func configuration(for level: EventLevel) -> GameConfiguration {
        GameConfiguration(
            puzzle: level.puzzle,
            pieceCount: level.pieceCount,
            rotationEnabled: false,
            table: preferences.load().table,
            isEventLevel: true
        )
    }
}

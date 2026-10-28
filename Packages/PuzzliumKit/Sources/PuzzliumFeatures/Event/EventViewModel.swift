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

    /// Postcards the player already knows about; a reload that returns from a level shows the rest.
    private var announced: Set<String>?

    func load(announcing: Bool = false) async {
        do {
            let fresh = try await useCase.execute(event)
            progress = fresh
            if announcing, let announced,
               let chapter = event.chapters.last(where: { fresh.collected.contains($0.id) && !announced.contains($0.id) }) {
                shownPostcard = chapter
            }
            // A plain reappear (cover still sliding away) must not swallow the reward.
            if announcing || announced == nil { announced = fresh.collected }
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

import Foundation
import Observation
import PuzzliumCore
import PuzzliumDomain

@Observable
@MainActor
final class HomeViewModel {
    enum State: Equatable {
        case loading
        case loaded(HomeFeed)
        case failed
    }

    private(set) var state: State = .loading
    private(set) var eventProgress: EventProgress?
    let event: PuzzleEvent?
    private let useCase: GetHomeFeedUseCase
    private let eventUseCase: GetEventProgressUseCase
    private let now: @Sendable () -> Date

    init(dependencies: FeatureDependencies) {
        useCase = GetHomeFeedUseCase(puzzles: dependencies.puzzles, progress: dependencies.progress)
        eventUseCase = GetEventProgressUseCase(progress: dependencies.progress)
        event = dependencies.event
        now = dependencies.now
    }

    var today: Date { now() }

    var feed: HomeFeed? {
        if case let .loaded(feed) = state { feed } else { nil }
    }

    func load() async {
        if let event {
            eventProgress = try? await eventUseCase.execute(event)
        }
        do {
            state = .loaded(try await useCase.execute(now: now()))
        } catch {
            Log.ui.error("Home feed failed: \(String(describing: error), privacy: .public)")
            if feed == nil { state = .failed }
        }
    }
}

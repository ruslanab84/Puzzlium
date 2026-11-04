import Foundation
import OSLog
import PuzzliumCore
import PuzzliumData
import PuzzliumDomain
import PuzzliumFeatures
import SwiftData

/// Composition root: the only place that knows concrete implementations.
@MainActor
final class AppContainer {
    let dependencies: FeatureDependencies

    private init(dependencies: FeatureDependencies) {
        self.dependencies = dependencies
    }

    static func live() -> AppContainer {
        let client: (any HTTPClient)? = AppConfiguration.apiBaseURL.map {
            URLSessionHTTPClient(configuration: APIConfiguration(baseURL: $0))
        }
        let ads = UnityAdsService()
        ads.start()
        return AppContainer(
            dependencies: FeatureDependencies(
                puzzles: DefaultPuzzleRepository(client: client),
                progress: SwiftDataProgressStore(modelContainer: makeModelContainer()),
                preferences: UserDefaultsPreferencesRepository(),
                images: PuzzleImageLoader(),
                analytics: LogAnalyticsTracker(),
                event: BundledEvent.autumn,
                ads: ads
            )
        )
    }

    private static func makeModelContainer() -> ModelContainer {
        do {
            return try PersistenceFactory.makeContainer()
        } catch {
            // A broken store must not block play: fall back to memory and report it.
            Log.data.fault("Persistent store unavailable: \(String(describing: error), privacy: .public)")
            do {
                return try PersistenceFactory.makeContainer(inMemory: true)
            } catch {
                fatalError("Unable to create even an in-memory store: \(error)")
            }
        }
    }
}

enum AppConfiguration {
    /// Remote catalog endpoint. `nil` keeps the app fully offline on the bundled catalog.
    static let apiBaseURL: URL? = nil
}

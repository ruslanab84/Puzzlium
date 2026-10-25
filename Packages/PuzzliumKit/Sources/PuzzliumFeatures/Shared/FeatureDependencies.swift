import Foundation
import PuzzliumCore
import PuzzliumDomain
import SwiftUI

/// Everything features need from the outside world. Built once by the app's composition root.
public struct FeatureDependencies: Sendable {
    public let puzzles: any PuzzleRepository
    public let progress: any ProgressRepository
    public let preferences: any PreferencesRepository
    public let images: any PuzzleImageProviding
    public let analytics: any AnalyticsTracking
    /// Current level event; `nil` hides it.
    public let event: PuzzleEvent?
    public let now: @Sendable () -> Date

    public init(
        puzzles: any PuzzleRepository,
        progress: any ProgressRepository,
        preferences: any PreferencesRepository,
        images: any PuzzleImageProviding,
        analytics: any AnalyticsTracking,
        event: PuzzleEvent? = nil,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.puzzles = puzzles
        self.progress = progress
        self.preferences = preferences
        self.images = images
        self.analytics = analytics
        self.event = event
        self.now = now
    }
}

extension EnvironmentValues {
    @Entry var imageProvider: (any PuzzleImageProviding)?
}

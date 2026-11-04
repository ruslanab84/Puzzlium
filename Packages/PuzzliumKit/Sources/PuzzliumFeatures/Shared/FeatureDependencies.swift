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
    /// Ad network; `nil` shows no ads (tests, previews).
    public let ads: (any AdServing)?
    public let now: @Sendable () -> Date

    public init(
        puzzles: any PuzzleRepository,
        progress: any ProgressRepository,
        preferences: any PreferencesRepository,
        images: any PuzzleImageProviding,
        analytics: any AnalyticsTracking,
        event: PuzzleEvent? = nil,
        ads: (any AdServing)? = nil,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.puzzles = puzzles
        self.progress = progress
        self.preferences = preferences
        self.images = images
        self.analytics = analytics
        self.event = event
        self.ads = ads
        self.now = now
    }
}

/// Ad network seen by features. The SDK itself lives in the app target.
@MainActor
public protocol AdServing: AnyObject, Sendable {
    /// Shows a rewarded video; `true` only when it was watched to the end.
    func showRewarded() async -> Bool
    /// Shows a full-screen ad if one is loaded; returns when it closes.
    func showInterstitial() async
    func banner() -> AnyView
}

extension EnvironmentValues {
    @Entry var imageProvider: (any PuzzleImageProviding)?
    @Entry var ads: (any AdServing)?
}

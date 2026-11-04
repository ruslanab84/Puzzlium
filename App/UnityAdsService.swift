import OSLog
import PuzzliumFeatures
import SwiftUI
import UIKit
import UnityAds

/// Unity Ads behind the features' `AdServing` protocol. One rewarded and one interstitial ad
/// are kept preloaded and replaced after each show, so a tap normally finds one ready.
@MainActor
final class UnityAdsService: AdServing {
    private enum Placement {
        static let rewarded = "BP_Rewarded_iOS"
        static let interstitial = "BP_Interstitial_iOS"
        static let banner = "BP_Banner_iOS"
    }

    private static let gameID = "800424050"
    nonisolated static let log = Logger(subsystem: "RuslanAbd.Puzzlium", category: "ads")

    private var rewarded: UADSRewardedAd?
    private var interstitial: UADSInterstitialAd?
    /// Unity keeps show delegates weakly; this holds the one for the ad on screen.
    private var observer: NSObject?

    func start() {
        #if DEBUG
        let testMode = true
        #else
        let testMode = false
        #endif
        let config = UADSInitializationConfigurationBuilder(gameId: Self.gameID).with(testMode: testMode).build()
        UnityAds.initialize(config) { @Sendable error in
            if let error {
                Self.log.error("Unity Ads init failed: \(String(describing: error), privacy: .public)")
                return
            }
            Task { @MainActor in
                self.loadRewarded()
                self.loadInterstitial()
            }
        }
    }

    func showRewarded() async -> Bool {
        guard let ad = rewarded, observer == nil, let presenter = Self.topViewController() else {
            loadRewarded()
            return false
        }
        rewarded = nil
        let completed = await withCheckedContinuation { continuation in
            let observer = RewardedObserver { continuation.resume(returning: $0) }
            self.observer = observer
            ad.show(Self.showConfig(presenter), delegate: observer)
        }
        observer = nil
        loadRewarded()
        return completed
    }

    func showInterstitial() async {
        guard let ad = interstitial, observer == nil, let presenter = Self.topViewController() else {
            loadInterstitial()
            return
        }
        interstitial = nil
        _ = await withCheckedContinuation { continuation in
            let observer = InterstitialObserver { continuation.resume(returning: $0) }
            self.observer = observer
            ad.show(Self.showConfig(presenter), delegate: observer)
        }
        observer = nil
        loadInterstitial()
    }

    func banner() -> AnyView {
        AnyView(
            UnityBanner(placement: Placement.banner)
                .frame(width: 320, height: 50)
                .frame(maxWidth: .infinity)
        )
    }

    private func loadRewarded() {
        guard UnityAds.isInitialized(), rewarded == nil else { return }
        UADSRewardedAd.load(UADSLoadConfigurationBuilder(placementId: Placement.rewarded).build()) { @Sendable ad, error in
            let ad = Unchecked(value: ad)
            Self.logLoad(Placement.rewarded, error)
            Task { @MainActor in self.rewarded = ad.value }
        }
    }

    private func loadInterstitial() {
        guard UnityAds.isInitialized(), interstitial == nil else { return }
        UADSInterstitialAd.load(UADSLoadConfigurationBuilder(placementId: Placement.interstitial).build()) { @Sendable ad, error in
            let ad = Unchecked(value: ad)
            Self.logLoad(Placement.interstitial, error)
            Task { @MainActor in self.interstitial = ad.value }
        }
    }

    private nonisolated static func logLoad(_ placement: String, _ error: (any UnityAdsError)?) {
        guard let error else { return }
        log.error("Ad \(placement, privacy: .public) failed to load: \(String(describing: error), privacy: .public)")
    }

    private static func showConfig(_ presenter: UIViewController) -> UADSShowConfiguration {
        UADSShowConfigurationBuilder().with(viewController: presenter).build()
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}

/// Carries an SDK object (not marked Sendable) from Unity's callback onto the main actor.
private struct Unchecked<Value>: @unchecked Sendable {
    let value: Value
}

/// Reports once whether the ad played to the end. Rewarded and interstitial delegates share
/// Objective-C selectors, so each format needs its own object.
private class ShowObserver: NSObject {
    private var report: ((Bool) -> Void)?

    init(report: @escaping (Bool) -> Void) {
        self.report = report
    }

    func finish(_ completed: Bool) {
        report?(completed)
        report = nil
    }

    func fail(_ error: any UnityAdsError) {
        UnityAdsService.log.error("Ad failed to show: \(String(describing: error), privacy: .public)")
        finish(false)
    }
}

private final class RewardedObserver: ShowObserver, UADSRewardedShowDelegate {
    func showDidComplete(_ unityAd: UADSRewardedAd, with finishState: UADSShowFinishState) { finish(finishState == .completed) }
    func showDidFail(_ unityAd: UADSRewardedAd, error: any UnityAdsError) { fail(error) }
    func showDidStart(_ unityAd: UADSRewardedAd) {}
    func showDidClick(_ unityAd: UADSRewardedAd) {}
    func showDidReceiveReward(_ unityAd: UADSRewardedAd) {}
}

private final class InterstitialObserver: ShowObserver, UADSInterstitialShowDelegate {
    func showDidComplete(_ unityAd: UADSInterstitialAd, with finishState: UADSShowFinishState) { finish(finishState == .completed) }
    func showDidFail(_ unityAd: UADSInterstitialAd, error: any UnityAdsError) { fail(error) }
    func showDidStart(_ unityAd: UADSInterstitialAd) {}
    func showDidClick(_ unityAd: UADSInterstitialAd) {}
}

/// 320×50 banner, loaded once when it first appears.
private struct UnityBanner: UIViewRepresentable {
    let placement: String

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        let config = UADSBannerLoadConfigurationBuilder(
            placementId: placement,
            bannerSize: CGSize(width: 320, height: 50),
            delegate: context.coordinator
        ).build()
        let target = Unchecked(value: (container, context.coordinator))
        UADSBannerAd.load(config) { @Sendable banner, error in
            guard let banner else {
                UnityAdsService.log.error("Banner failed to load: \(String(describing: error), privacy: .public)")
                return
            }
            let loaded = Unchecked(value: banner)
            Task { @MainActor in
                let ad = loaded.value
                let (container, coordinator) = target.value
                coordinator.banner = ad
                ad.view.frame = container.bounds
                ad.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                container.addSubview(ad.view)
            }
        }
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    final class Coordinator: NSObject, UADSBannerAdDelegate {
        /// The SDK hands back the ad object; keeping it alive keeps the banner on screen.
        var banner: UADSBannerAd?

        func bannerImpression(_ banner: UADSBannerAd) {}
        func bannerDidClick(_ banner: UADSBannerAd) {}
        func bannerDidFailShow(_ banner: UADSBannerAd, error: any UnityAdsError) {
            UnityAdsService.log.error("Banner failed to show: \(String(describing: error), privacy: .public)")
        }
    }
}

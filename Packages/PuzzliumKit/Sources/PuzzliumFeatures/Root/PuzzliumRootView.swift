import PuzzliumDesignSystem
import SwiftUI

public struct PuzzliumRootView: View {
    private let dependencies: FeatureDependencies
    @State private var router = AppRouter()
    @State private var packs = PackStore()
    @State private var showIntro = true
    @State private var gamesClosed = 0

    public init(dependencies: FeatureDependencies) {
        self.dependencies = dependencies
    }

    public var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            NavigationStack {
                HomeView(dependencies: dependencies)
            }
            .tabItem { Label(L10n.Tab.today, systemImage: "sun.max") }
            .tag(AppRouter.Tab.today)

            NavigationStack {
                LibraryView(dependencies: dependencies)
            }
            .tabItem { Label(L10n.Tab.library, systemImage: "square.grid.2x2") }
            .tag(AppRouter.Tab.library)

            NavigationStack {
                MyPuzzlesView(dependencies: dependencies)
            }
            .tabItem { Label(L10n.Tab.myPuzzles, systemImage: "puzzlepiece") }
            .tag(AppRouter.Tab.myPuzzles)
        }
        .tint(PZColor.accentText)
        .overlay {
            if showIntro {
                IntroView { showIntro = false }
            }
        }
        .environment(router)
        .environment(packs)
        .environment(\.imageProvider, dependencies.images)
        .environment(\.ads, dependencies.ads)
        .task { await packs.run() }
        .sheet(item: $router.setupPuzzle, onDismiss: { router.setupDismissed() }) { puzzle in
            PuzzleSetupView(puzzle: puzzle, dependencies: dependencies)
                .environment(router)
                .environment(\.imageProvider, dependencies.images)
        }
        .fullScreenCover(item: $router.activeGame, onDismiss: gameDismissed) { configuration in
            GameView(configuration: configuration, dependencies: dependencies)
                .environment(router)
                .environment(\.imageProvider, dependencies.images)
        }
    }

    /// Every third closed game shows an interstitial, never to someone who bought a pack.
    // ponytail: counter resets on launch; persist it if players restart the app to dodge ads.
    private func gameDismissed() {
        router.gameDismissed()
        gamesClosed += 1
        guard gamesClosed.isMultiple(of: 3), !packs.access.hasPurchased, let ads = dependencies.ads else { return }
        Task { await ads.showInterstitial() }
    }
}

import PuzzliumDesignSystem
import SwiftUI

public struct PuzzliumRootView: View {
    private let dependencies: FeatureDependencies
    @State private var router = AppRouter()

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
        .environment(router)
        .environment(\.imageProvider, dependencies.images)
        .sheet(item: $router.setupPuzzle, onDismiss: { router.setupDismissed() }) { puzzle in
            PuzzleSetupView(puzzle: puzzle, dependencies: dependencies)
                .environment(router)
                .environment(\.imageProvider, dependencies.images)
        }
        .fullScreenCover(item: $router.activeGame) { configuration in
            GameView(configuration: configuration, dependencies: dependencies)
                .environment(router)
                .environment(\.imageProvider, dependencies.images)
        }
    }
}

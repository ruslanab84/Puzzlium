import PuzzliumFeatures
import SwiftUI

@main
struct PuzzliumApp: App {
    @State private var container = AppContainer.live()

    var body: some Scene {
        WindowGroup {
            PuzzliumRootView(dependencies: container.dependencies)
        }
    }
}

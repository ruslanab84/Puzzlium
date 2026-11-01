import PuzzliumFeatures
import SwiftUI

@main
struct PuzzliumApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var container = AppContainer.live()

    var body: some Scene {
        WindowGroup {
            PuzzliumRootView(dependencies: container.dependencies)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    /// Phones stay portrait unless the screen is big enough for the side-by-side game
    /// layout, which today means the unfolded iPhone Duo.
    // ponytail: keyed on screen size, not a device check; untested on a real Duo fold/unfold.
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return .all }
        let size = window?.windowScene?.screen.bounds.size ?? .zero
        return min(size.width, size.height) >= 600 ? .allButUpsideDown : .portrait
    }
}

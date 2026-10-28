import FoundationModels
import ImagePlayground
import SwiftUI

/// "Generate a picture" menu entry. Shown only on devices with Apple Intelligence:
/// the on-device Foundation Model is ready and Image Playground is allowed here.
struct PlaygroundMenuButton: View {
    let action: () -> Void

    var body: some View {
        if #available(iOS 26, *) {
            Available(action: action)
        }
    }

    @available(iOS 26, *)
    private struct Available: View {
        let action: () -> Void
        @Environment(\.supportsImagePlayground) private var supportsImagePlayground

        var body: some View {
            if supportsImagePlayground, SystemLanguageModel.default.isAvailable {
                Button(L10n.Library.generatePhoto, systemImage: "apple.image.playground", action: action)
            }
        }
    }
}

extension View {
    /// System Image Playground sheet; hands back the generated picture. A no-op before iOS 26.
    @ViewBuilder
    func playgroundSheet(isPresented: Binding<Bool>, onCompletion: @escaping (Data?) -> Void) -> some View {
        if #available(iOS 26, *) {
            imagePlaygroundSheet(isPresented: isPresented) { url in
                onCompletion(try? Data(contentsOf: url))
            }
        } else {
            self
        }
    }
}

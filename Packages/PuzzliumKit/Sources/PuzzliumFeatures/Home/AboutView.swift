import PuzzliumDesignSystem
import SwiftUI

/// Links App Review expects inside the app: privacy policy, terms, support. Plus restore.
enum AppLinks {
    /// Published from docs/ via GitHub Pages.
    static let privacy = URL(string: "https://ruslanab84.github.io/Puzzlium/privacy.html")!
    static let support = URL(string: "https://github.com/ruslanab84/Puzzlium/issues")!
    /// Apple's standard EULA; replace if a custom EULA is set in App Store Connect.
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
}

struct AboutView: View {
    @Environment(PackStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "–"
        let build = info?["CFBundleVersion"] as? String ?? "–"
        return "\(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Link(L10n.About.privacy, destination: AppLinks.privacy)
                    Link(L10n.About.terms, destination: AppLinks.terms)
                    Link(L10n.About.support, destination: AppLinks.support)
                }
                Section {
                    Button(L10n.Pack.restore) { Task { await store.restore() } }
                        .disabled(store.isPurchasing)
                }
                Section {
                    LabeledContent(L10n.About.version) { Text(verbatim: version) }
                }
            }
            .tint(PZColor.accentText)
            .navigationTitle(L10n.About.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.done) { dismiss() }
                }
            }
        }
    }
}

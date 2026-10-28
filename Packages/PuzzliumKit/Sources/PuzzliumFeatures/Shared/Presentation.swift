import PuzzliumDesignSystem
import PuzzliumDomain
import SwiftUI

extension PuzzleCategory {
    var title: String {
        switch self {
        case .nature: L10n.Category.nature
        case .flowers: L10n.Category.flowers
        case .kids: L10n.Category.kids
        case .cities: L10n.Category.cities
        case .art: L10n.Category.art
        case .landmarks: L10n.Category.landmarks
        case .countries: L10n.Category.countries
        }
    }
}

extension TableSurface {
    var title: String {
        switch self {
        case .felt: L10n.Table.felt
        case .walnut: L10n.Table.walnut
        case .slate: L10n.Table.slate
        case .linen: L10n.Table.linen
        }
    }

    var color: Color {
        switch self {
        case .felt: PZColor.felt
        case .walnut: Color(hex: 0x5A3E2B)
        case .slate: Color(hex: 0x2F3A45)
        case .linen: Color(hex: 0xE9E4DA)
        }
    }

    var isLight: Bool { self == .linen }

    /// Foreground for text and icons drawn directly on the table.
    var content: Color { isLight ? Color(hex: 0x18201D) : PZColor.onFelt }
    var contentMuted: Color { isLight ? Color(hex: 0x4E5752) : PZColor.onFeltMuted }
    var raised: Color { isLight ? Color.black.opacity(0.06) : Color.white.opacity(0.12) }
    var tray: Color { isLight ? Color(hex: 0xDDD6C9) : Color.black.opacity(0.22) }
}

enum TimeText {
    static func clock(_ seconds: TimeInterval) -> String {
        let duration = Duration.seconds(max(0, seconds.rounded(.down)))
        return seconds >= 3600
            ? duration.formatted(.time(pattern: .hourMinuteSecond))
            : duration.formatted(.time(pattern: .minuteSecond))
    }
}

/// Square puzzle art loaded through the injected image provider.
struct PuzzleArtView: View {
    let source: PuzzleImageSource
    var pixelSize = 512

    @Environment(\.imageProvider) private var provider
    @State private var image: PuzzleImage?

    var body: some View {
        Rectangle()
            .fill(PZColor.felt.opacity(0.18))
            .overlay {
                if let image {
                    Image(decorative: image.cgImage, scale: 1)
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity)
                }
            }
            .clipped()
            .animation(.easeOut(duration: 0.2), value: image != nil)
            .task(id: source) {
                guard let provider else { return }
                image = try? await provider.image(for: source, pixelSize: pixelSize)
            }
            .accessibilityHidden(true)
    }
}

struct ErrorStateView: View {
    let message: String
    var tint: Color = PZColor.ink
    let retry: () -> Void

    var body: some View {
        VStack(spacing: PZSpacing.l) {
            Image(systemName: "wifi.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(tint.opacity(0.6))
                .accessibilityHidden(true)
            Text(message)
                .font(PZFont.headline)
                .foregroundStyle(tint)
                .multilineTextAlignment(.center)
            Button(L10n.Common.retry, action: retry)
                .buttonStyle(.pzPrimary)
                .frame(maxWidth: 240)
        }
        .frame(maxWidth: .infinity, minHeight: 280)
    }
}

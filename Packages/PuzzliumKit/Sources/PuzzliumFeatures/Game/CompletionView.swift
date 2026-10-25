import PuzzliumDesignSystem
import PuzzliumDomain
import SwiftUI

struct CompletionView: View {
    let puzzle: Puzzle
    let image: CGImage?
    let summary: CompletionSummary
    let table: TableSurface
    var nextTitle = L10n.Done.next
    /// Event levels are not listed in My puzzles, so they pass `nil`.
    var savedNote: String? = L10n.Done.saved
    let onNext: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: PZSpacing.xl) {
            HStack {
                Spacer()
                Button(L10n.Common.close, systemImage: "xmark", action: onClose)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.pzCircle(background: table.raised, foreground: table.content))
            }

            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .padding(10)
                    .background(.white, in: RoundedRectangle(cornerRadius: 8))
                    .rotationEffect(.degrees(-2))
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 18)
                    .frame(maxWidth: 320)
                    .accessibilityHidden(true)
            }

            VStack(spacing: PZSpacing.s) {
                Text(L10n.Done.badge.uppercased())
                    .font(PZFont.eyebrow)
                    .tracking(1)
                    .foregroundStyle(PZColor.amber)
                Text(puzzle.title)
                    .font(PZFont.largeTitle)
                    .foregroundStyle(table.content)
                    .multilineTextAlignment(.center)
                if let savedNote {
                    Text(savedNote)
                        .font(PZFont.callout)
                        .foregroundStyle(table.contentMuted)
                }
            }

            HStack(spacing: PZSpacing.s) {
                stat(L10n.Done.time, TimeText.clock(summary.duration))
                stat(L10n.Done.pieces, String(summary.pieceCount))
                stat(L10n.Done.streak, L10n.Done.streakValue(summary.streak))
            }

            Spacer(minLength: 0)

            VStack(spacing: PZSpacing.m) {
                Button(nextTitle, action: onNext)
                    .buttonStyle(.pzPrimary(background: PZColor.amber, foreground: Color(hex: 0x18201D)))
                if let image {
                    let shareImage = Image(decorative: image, scale: 1)
                    ShareLink(item: shareImage, preview: SharePreview(puzzle.title, image: shareImage)) {
                        Label(L10n.Done.share, systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(PZOutlineButtonStyle(tint: table.content))
                }
            }
        }
        .padding(.horizontal, PZSpacing.xl)
        .padding(.vertical, PZSpacing.l)
        .frame(maxWidth: 560)
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(PZFont.caption)
                .foregroundStyle(table.contentMuted)
            Text(value)
                .font(PZFont.number(.title3))
                .foregroundStyle(table.content)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 64)
        .background(table.raised, in: RoundedRectangle(cornerRadius: PZRadius.m, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

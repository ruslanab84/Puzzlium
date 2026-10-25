import PuzzliumDesignSystem
import PuzzliumDomain
import SwiftUI

struct DailyPuzzleCard: View {
    let puzzle: Puzzle
    let progress: PuzzleProgress?
    let onPlay: () -> Void

    private var solvedToday: Bool {
        guard let completedAt = progress?.completedAt else { return false }
        return Calendar.current.isDateInToday(completedAt)
    }

    var body: some View {
        Button(action: onPlay) {
            PuzzleArtView(source: puzzle.image, pixelSize: 900)
                .frame(height: 300)
                .overlay(alignment: .topLeading) {
                    Text(L10n.Home.dailyBadge.uppercased())
                        .font(PZFont.eyebrow)
                        .tracking(0.6)
                        .foregroundStyle(.white)
                        .padding(.horizontal, PZSpacing.m)
                        .frame(minHeight: 28)
                        .background(Color(hex: 0x18201D), in: Capsule())
                        .padding(PZSpacing.l)
                }
                .overlay(alignment: .bottom) { infoPanel }
                .clipShape(RoundedRectangle(cornerRadius: PZRadius.xl, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint(L10n.Home.play)
        .accessibilityIdentifier("home.daily")
    }

    private var infoPanel: some View {
        HStack(spacing: PZSpacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text(puzzle.title)
                    .font(PZFont.title3)
                    .foregroundStyle(PZColor.ink)
                Text(subtitle)
                    .font(PZFont.footnote)
                    .foregroundStyle(PZColor.muted)
            }
            Spacer(minLength: 0)
            Text(L10n.Home.play)
                .font(PZFont.headline)
                .foregroundStyle(PZColor.onFelt)
                .padding(.horizontal, PZSpacing.xl)
                .frame(minHeight: 48)
                .background(PZColor.felt, in: Capsule())
        }
        .padding(.vertical, PZSpacing.m)
        .padding(.leading, PZSpacing.l + 2)
        .padding(.trailing, PZSpacing.m + 2)
        .background(PZColor.surface, in: RoundedRectangle(cornerRadius: PZRadius.l, style: .continuous))
        .padding(PZSpacing.m)
    }

    private var subtitle: String {
        if solvedToday { return L10n.Home.dailySolved }
        if let progress, progress.isInProgress {
            return L10n.Game.progress(progress.placedCount, progress.pieceCount.rawValue)
        }
        let count = puzzle.recommendedPieceCount
        return L10n.Home.piecesAndTime(count.rawValue, count.estimatedMinutes)
    }
}

struct ContinueSection: View {
    let items: [PuzzleEntry]
    let onSelect: (PuzzleEntry) -> Void
    let onSeeAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PZSpacing.m) {
            HStack {
                Text(L10n.Home.continueTitle)
                    .font(PZFont.title)
                    .foregroundStyle(PZColor.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if !items.isEmpty {
                    Button(L10n.Home.seeAll, action: onSeeAll)
                        .font(PZFont.callout.weight(.bold))
                        .foregroundStyle(PZColor.accentText)
                }
            }
            if items.isEmpty {
                Text(L10n.Home.continueEmpty)
                    .font(PZFont.callout)
                    .foregroundStyle(PZColor.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .pzCard()
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: PZSpacing.m), GridItem(.flexible())], spacing: PZSpacing.l) {
                    ForEach(items) { item in
                        Button { onSelect(item) } label: {
                            ContinueTile(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct ContinueTile: View {
    let item: PuzzleEntry

    var body: some View {
        let fraction = item.progress?.fraction ?? 0
        VStack(alignment: .leading, spacing: PZSpacing.s) {
            PuzzleArtView(source: item.puzzle.image, pixelSize: 360)
                .frame(height: 104)
                .clipShape(RoundedRectangle(cornerRadius: PZRadius.m, style: .continuous))
            Text(item.puzzle.title)
                .font(PZFont.callout.weight(.bold))
                .foregroundStyle(PZColor.ink)
                .lineLimit(1)
            HStack(spacing: PZSpacing.s) {
                PZProgressBar(value: fraction)
                Text(fraction, format: .percent.precision(.fractionLength(0)))
                    .font(PZFont.caption.monospacedDigit())
                    .foregroundStyle(PZColor.muted)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct NewArrivalsRow: View {
    let puzzles: [Puzzle]
    let onSelect: (Puzzle) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PZSpacing.m) {
            Text(L10n.Home.newArrivals)
                .font(PZFont.title)
                .foregroundStyle(PZColor.ink)
                .accessibilityAddTraits(.isHeader)
            ScrollView(.horizontal) {
                LazyHStack(spacing: PZSpacing.m) {
                    ForEach(puzzles) { puzzle in
                        Button { onSelect(puzzle) } label: {
                            VStack(alignment: .leading, spacing: PZSpacing.s) {
                                PuzzleArtView(source: puzzle.image, pixelSize: 360)
                                    .frame(width: 140, height: 140)
                                    .clipShape(RoundedRectangle(cornerRadius: PZRadius.m, style: .continuous))
                                Text(puzzle.title)
                                    .font(PZFont.callout.weight(.bold))
                                    .foregroundStyle(PZColor.ink)
                                    .lineLimit(1)
                                    .frame(width: 140, alignment: .leading)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
    }
}

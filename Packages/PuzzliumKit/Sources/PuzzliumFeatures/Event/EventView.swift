import PuzzliumDesignSystem
import PuzzliumDomain
import SwiftUI

/// Level list of an event: chapters of levels that open one by one, postcards as rewards.
struct EventView: View {
    @State private var viewModel: EventViewModel
    @Environment(AppRouter.self) private var router

    init(event: PuzzleEvent, dependencies: FeatureDependencies) {
        _viewModel = State(initialValue: EventViewModel(event: event, dependencies: dependencies))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        let event = viewModel.event

        ScrollView {
            VStack(alignment: .leading, spacing: PZSpacing.xl) {
                header
                postcards
                ForEach(Array(event.chapters.enumerated()), id: \.element.id) { index, chapter in
                    chapterSection(chapter, number: index + 1, firstLevel: levelOffset(of: index))
                }
            }
            .padding(.horizontal, PZSpacing.xl)
            .padding(.top, PZSpacing.s)
            .padding(.bottom, PZSpacing.xxl)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(PZColor.ground)
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        // Bumped only after the game cover is gone: the one reload allowed to hand out a postcard.
        .onChange(of: router.contentVersion) { Task { await viewModel.load(announcing: true) } }
        .sheet(item: $viewModel.shownPostcard) { chapter in
            PostcardRewardView(
                chapter: chapter,
                isFinale: viewModel.progress?.isFinished == true && chapter.id == event.chapters.last?.id
            )
        }
    }

    private var header: some View {
        let done = viewModel.progress?.completedCount ?? 0
        let total = viewModel.event.levels.count
        return VStack(alignment: .leading, spacing: PZSpacing.s) {
            Text(L10n.Event.badge.uppercased())
                .font(PZFont.eyebrow)
                .tracking(0.6)
                .foregroundStyle(PZColor.ember)
            Text(viewModel.event.title)
                .font(PZFont.largeTitle)
                .foregroundStyle(PZColor.ink)
                .accessibilityAddTraits(.isHeader)
            Text(L10n.Event.levels(done, total))
                .font(PZFont.footnote.weight(.bold))
                .foregroundStyle(PZColor.muted)
            PZProgressBar(value: Double(done) / Double(max(total, 1)), tint: PZColor.amber, height: 6)
        }
    }

    private var postcards: some View {
        let chapters = viewModel.event.chapters
        return VStack(alignment: .leading, spacing: PZSpacing.m) {
            HStack {
                Text(L10n.Event.postcards)
                    .font(PZFont.title)
                    .foregroundStyle(PZColor.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text(L10n.Event.postcardCount(viewModel.progress?.collected.count ?? 0, chapters.count))
                    .font(PZFont.footnote)
                    .foregroundStyle(PZColor.muted)
            }
            HStack(alignment: .top, spacing: PZSpacing.m) {
                ForEach(Array(chapters.enumerated()), id: \.element.id) { index, chapter in
                    let collected = viewModel.isCollected(chapter)
                    Button { viewModel.shownPostcard = chapter } label: {
                        VStack(spacing: PZSpacing.s) {
                            PostcardView(chapter: chapter, isCollected: collected, pixelSize: 360)
                            Text(collected ? chapter.postcardTitle : L10n.Event.postcardLocked(index + 1))
                                .font(PZFont.caption.weight(collected ? .bold : .regular))
                                .foregroundStyle(collected ? PZColor.ink : PZColor.muted)
                                .multilineTextAlignment(.center)
                                .lineLimit(2, reservesSpace: true)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!collected)
                    .accessibilityIdentifier("event.postcard")
                }
            }
        }
    }

    private func chapterSection(_ chapter: EventChapter, number: Int, firstLevel: Int) -> some View {
        VStack(alignment: .leading, spacing: PZSpacing.m) {
            HStack(spacing: PZSpacing.s) {
                Text(L10n.Event.chapter(number))
                    .font(PZFont.title3)
                    .foregroundStyle(PZColor.ink)
                    .accessibilityAddTraits(.isHeader)
                if viewModel.isCollected(chapter) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(PZColor.amber)
                        .accessibilityLabel(L10n.Event.completed)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: PZSpacing.m), count: 3), spacing: PZSpacing.l) {
                ForEach(Array(chapter.levels.enumerated()), id: \.element.id) { index, level in
                    let status = viewModel.status(of: level)
                    Button { router.play(viewModel.configuration(for: level)) } label: {
                        LevelTile(number: firstLevel + index + 1, level: level, status: status)
                    }
                    .buttonStyle(.plain)
                    .disabled(!status.isPlayable)
                    .accessibilityIdentifier("event.level")
                }
            }
        }
    }

    private func levelOffset(of chapterIndex: Int) -> Int {
        viewModel.event.chapters.prefix(chapterIndex).reduce(0) { $0 + $1.levels.count }
    }
}

private extension LevelStatus {
    var isPlayable: Bool {
        switch self {
        case .available, .inProgress: true
        case .locked, .completed: false
        }
    }
}

private struct LevelTile: View {
    let number: Int
    let level: EventLevel
    let status: LevelStatus

    var body: some View {
        VStack(alignment: .leading, spacing: PZSpacing.xs) {
            PuzzleArtView(source: level.puzzle.image, pixelSize: 300)
                .aspectRatio(1, contentMode: .fit)
                .blur(radius: status == .locked ? 8 : 0)
                .overlay {
                    if status == .locked {
                        Color.black.opacity(0.3)
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: PZRadius.m, style: .continuous))
                .overlay(alignment: .topLeading) {
                    Text(verbatim: "\(number)")
                        .font(PZFont.number(.caption))
                        .foregroundStyle(.white)
                        .frame(minWidth: 24, minHeight: 24)
                        .background(Color(hex: 0x18201D).opacity(0.8), in: Circle())
                        .padding(PZSpacing.xs + 2)
                }
                .overlay(alignment: .topTrailing) {
                    if status == .completed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, PZColor.felt)
                            .padding(PZSpacing.xs + 2)
                    }
                }
                .overlay {
                    if status == .available {
                        RoundedRectangle(cornerRadius: PZRadius.m, style: .continuous)
                            .strokeBorder(PZColor.amber, lineWidth: 3)
                    }
                }
            Text(level.puzzle.title)
                .font(PZFont.footnote.weight(.bold))
                .foregroundStyle(status == .locked ? PZColor.muted : PZColor.ink)
                .lineLimit(1)
            if case let .inProgress(fraction) = status {
                PZProgressBar(value: fraction, tint: PZColor.amber)
                    .padding(.vertical, 5)
            } else {
                Text(L10n.Event.pieces(level.pieceCount.rawValue))
                    .font(PZFont.caption)
                    .foregroundStyle(PZColor.muted)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.Event.level(number))
        .accessibilityValue(accessibilityStatus)
    }

    private var accessibilityStatus: String {
        let base = "\(level.puzzle.title), \(L10n.Event.pieces(level.pieceCount.rawValue))"
        return switch status {
        case .locked: "\(base). \(L10n.Event.locked)"
        case .completed: "\(base). \(L10n.Event.completed)"
        case let .inProgress(fraction): "\(base). \(fraction.formatted(.percent.precision(.fractionLength(0))))"
        case .available: base
        }
    }
}

/// A picture with a white border and a stamp; greyed and locked until its chapter is done.
struct PostcardView: View {
    let chapter: EventChapter
    let isCollected: Bool
    var pixelSize = 512

    var body: some View {
        PuzzleArtView(source: chapter.postcard, pixelSize: pixelSize)
            .aspectRatio(1.4, contentMode: .fit)
            .saturation(isCollected ? 1 : 0)
            .blur(radius: isCollected ? 0 : 5)
            .overlay {
                if !isCollected {
                    Color.white.opacity(0.35)
                    Image(systemName: "lock.fill")
                        .foregroundStyle(PZColor.muted)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay(alignment: .topTrailing) {
                if isCollected {
                    Image(systemName: "leaf.fill")
                        .font(.caption2)
                        .foregroundStyle(PZColor.ember)
                        .frame(width: 20, height: 22)
                        .background(Color(hex: 0xFFF6E5))
                        .overlay(Rectangle().strokeBorder(PZColor.ember, style: StrokeStyle(lineWidth: 1, dash: [2, 2])))
                        .rotationEffect(.degrees(6))
                        .padding(4)
                }
            }
            .padding(5)
            .background(.white, in: RoundedRectangle(cornerRadius: 6))
            .shadow(color: .black.opacity(isCollected ? 0.18 : 0.06), radius: 6, y: 4)
            .accessibilityElement()
            .accessibilityLabel(isCollected ? chapter.postcardTitle : L10n.Event.postcards)
    }
}

private struct PostcardRewardView: View {
    let chapter: EventChapter
    let isFinale: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false

    var body: some View {
        VStack(spacing: PZSpacing.xl) {
            Spacer(minLength: 0)
            PostcardView(chapter: chapter, isCollected: true, pixelSize: 900)
                .frame(maxWidth: 340)
                .rotationEffect(.degrees(appeared ? -3 : -12))
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)
            VStack(spacing: PZSpacing.s) {
                Text((isFinale ? L10n.Event.finishedTitle : L10n.Event.rewardTitle).uppercased())
                    .font(PZFont.eyebrow)
                    .tracking(1)
                    .foregroundStyle(PZColor.ember)
                Text(chapter.postcardTitle)
                    .font(PZFont.largeTitle)
                    .foregroundStyle(PZColor.ink)
                    .multilineTextAlignment(.center)
                Text(isFinale ? L10n.Event.finishedBody : L10n.Event.rewardBody)
                    .font(PZFont.callout)
                    .foregroundStyle(PZColor.muted)
                    .multilineTextAlignment(.center)
            }
            Spacer(minLength: 0)
            Button(L10n.Common.done) { dismiss() }
                .buttonStyle(.pzPrimary(background: PZColor.felt, foreground: PZColor.onFelt))
                .accessibilityIdentifier("event.rewardDone")
        }
        .padding(PZSpacing.xl)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
        .background(PZColor.ground)
        .sensoryFeedback(.success, trigger: appeared)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.35)) { appeared = true }
        }
    }
}

/// Home entry point for the event.
struct EventCard: View {
    let event: PuzzleEvent
    let progress: EventProgress?

    var body: some View {
        let done = progress?.completedCount ?? 0
        let total = event.levels.count
        // The next level to play, not the postcard: rewards stay a surprise.
        let current = event.levels.first { progress?.status(of: $0) != .completed } ?? event.levels.last
        HStack(spacing: PZSpacing.l) {
            PuzzleArtView(source: current?.puzzle.image ?? .procedural(style: .dunes, variant: 3), pixelSize: 240)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: PZRadius.s, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.Event.badge.uppercased())
                    .font(PZFont.eyebrow)
                    .tracking(0.6)
                    .foregroundStyle(PZColor.ember)
                Text(event.title)
                    .font(PZFont.title3)
                    .foregroundStyle(PZColor.ink)
                Text(L10n.Event.levels(done, total))
                    .font(PZFont.footnote)
                    .foregroundStyle(PZColor.muted)
                PZProgressBar(value: Double(done) / Double(max(total, 1)), tint: PZColor.amber)
            }
            Image(systemName: "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(PZColor.muted)
        }
        .pzCard()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("home.event")
    }
}

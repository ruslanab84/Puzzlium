import PuzzliumDesignSystem
import PuzzliumDomain
import SwiftUI

/// Started and finished puzzles. Reuses the library view model (same data, different slices).
struct MyPuzzlesView: View {
    @State private var viewModel: LibraryViewModel
    @Environment(AppRouter.self) private var router

    init(dependencies: FeatureDependencies) {
        _viewModel = State(initialValue: LibraryViewModel(dependencies: dependencies))
    }

    var body: some View {
        List {
            if !viewModel.inProgress.isEmpty {
                section(L10n.My.inProgress, items: viewModel.inProgress)
            }
            if !viewModel.completed.isEmpty {
                section(L10n.My.completed, items: viewModel.completed)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(PZColor.ground)
        .overlay {
            if !viewModel.isLoading, viewModel.inProgress.isEmpty, viewModel.completed.isEmpty {
                ContentUnavailableView(L10n.My.title, systemImage: "puzzlepiece", description: Text(L10n.My.empty))
            }
        }
        .navigationTitle(L10n.My.title)
        .task(id: router.contentVersion) { await viewModel.load() }
    }

    private func section(_ title: String, items: [PuzzleEntry]) -> some View {
        Section(title) {
            ForEach(items) { item in
                Button { router.openSetup(for: item.puzzle) } label: {
                    MyPuzzleRow(item: item)
                }
                .listRowBackground(PZColor.surface)
            }
        }
    }
}

private struct MyPuzzleRow: View {
    let item: PuzzleEntry

    var body: some View {
        HStack(spacing: PZSpacing.m) {
            PuzzleArtView(source: item.puzzle.image, pixelSize: 160)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: PZRadius.s, style: .continuous))
            VStack(alignment: .leading, spacing: PZSpacing.xs) {
                Text(item.puzzle.title)
                    .font(PZFont.callout.weight(.bold))
                    .foregroundStyle(PZColor.ink)
                if case let .inProgress(fraction) = item.status {
                    PZProgressBar(value: fraction)
                        .frame(maxWidth: 160)
                } else if let progress = item.progress {
                    Text(verbatim: "\(progress.pieceCount.rawValue) · \(TimeText.clock(progress.elapsed))")
                        .font(PZFont.caption.monospacedDigit())
                        .foregroundStyle(PZColor.muted)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(PZColor.muted)
                .accessibilityHidden(true)
        }
        .padding(.vertical, PZSpacing.xs)
        .accessibilityElement(children: .combine)
    }
}

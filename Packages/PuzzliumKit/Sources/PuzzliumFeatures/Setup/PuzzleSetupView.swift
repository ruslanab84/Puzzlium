import PuzzliumDesignSystem
import PuzzliumDomain
import SwiftUI

struct PuzzleSetupView: View {
    @State private var viewModel: PuzzleSetupViewModel
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss

    init(puzzle: Puzzle, dependencies: FeatureDependencies) {
        _viewModel = State(initialValue: PuzzleSetupViewModel(puzzle: puzzle, dependencies: dependencies))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PZSpacing.xl) {
                    header
                    PieceCountPicker(options: viewModel.puzzle.pieceCounts, selection: $viewModel.pieceCount)
                    rotationToggle
                    TablePicker(selection: $viewModel.table)
                }
                .padding(PZSpacing.xl)
            }
            .background(PZColor.ground)
            .safeAreaInset(edge: .bottom) { startButton }
            .navigationTitle(L10n.Setup.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.close, systemImage: "xmark") { dismiss() }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .task { await viewModel.load() }
    }

    private var header: some View {
        HStack(spacing: PZSpacing.l) {
            PuzzleArtView(source: viewModel.puzzle.image, pixelSize: 360)
                .frame(width: 112, height: 112)
                .clipShape(RoundedRectangle(cornerRadius: PZRadius.l, style: .continuous))
            VStack(alignment: .leading, spacing: PZSpacing.xs) {
                Text(viewModel.puzzle.category.title.uppercased())
                    .font(PZFont.eyebrow)
                    .foregroundStyle(PZColor.accentText)
                Text(viewModel.puzzle.title)
                    .font(PZFont.title)
                    .foregroundStyle(PZColor.ink)
                Text(L10n.Setup.offlineNote)
                    .font(PZFont.footnote)
                    .foregroundStyle(PZColor.muted)
            }
        }
    }

    private var rotationToggle: some View {
        @Bindable var viewModel = viewModel
        return Toggle(isOn: $viewModel.rotationEnabled) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.Setup.rotation)
                    .font(PZFont.headline)
                    .foregroundStyle(PZColor.ink)
                Text(L10n.Setup.rotationHint)
                    .font(PZFont.footnote)
                    .foregroundStyle(PZColor.muted)
            }
        }
        .tint(PZColor.felt)
        .pzCard()
    }

    private var startButton: some View {
        Button {
            router.start(viewModel.makeConfiguration())
        } label: {
            Text(viewModel.resumesSavedGame ? L10n.Setup.resume : L10n.Setup.start(viewModel.pieceCount.rawValue))
        }
        .buttonStyle(.pzPrimary)
        .accessibilityIdentifier("setup.start")
        .padding(.horizontal, PZSpacing.xl)
        .padding(.vertical, PZSpacing.m)
        .background(PZColor.ground)
    }
}

private struct PieceCountPicker: View {
    let options: [PieceCount]
    @Binding var selection: PieceCount

    private let columns = Array(repeating: GridItem(.flexible(), spacing: PZSpacing.s), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: PZSpacing.m) {
            Text(L10n.Setup.pieces)
                .font(PZFont.headline)
                .foregroundStyle(PZColor.ink)
                .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: columns, spacing: PZSpacing.s) {
                ForEach(options) { option in
                    let isSelected = option == selection
                    Button { selection = option } label: {
                        VStack(spacing: 2) {
                            Text(option.rawValue, format: .number)
                                .font(PZFont.number(.title3))
                            Text(L10n.Setup.minutes(option.estimatedMinutes))
                                .font(PZFont.caption)
                                .opacity(0.8)
                        }
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .foregroundStyle(isSelected ? PZColor.onFelt : PZColor.ink)
                        .background(isSelected ? PZColor.felt : PZColor.surface, in: RoundedRectangle(cornerRadius: PZRadius.m, style: .continuous))
                        .overlay {
                            if !isSelected {
                                RoundedRectangle(cornerRadius: PZRadius.m, style: .continuous).strokeBorder(PZColor.divider)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

private struct TablePicker: View {
    @Binding var selection: TableSurface

    var body: some View {
        VStack(alignment: .leading, spacing: PZSpacing.m) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.Setup.table)
                    .font(PZFont.headline)
                    .foregroundStyle(PZColor.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text(selection.title)
                    .font(PZFont.footnote)
                    .foregroundStyle(PZColor.muted)
            }
            HStack(spacing: PZSpacing.m) {
                ForEach(TableSurface.allCases, id: \.self) { style in
                    let isSelected = style == selection
                    Button { selection = style } label: {
                        Circle()
                            .fill(style.color)
                            .padding(isSelected ? 4 : 5)
                            .frame(width: 48, height: 48)
                            .overlay {
                                Circle().strokeBorder(isSelected ? PZColor.amber : PZColor.divider, lineWidth: isSelected ? 3 : 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(style.title)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }
}

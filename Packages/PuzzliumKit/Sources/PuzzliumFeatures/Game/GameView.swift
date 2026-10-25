import PuzzliumDesignSystem
import PuzzliumDomain
import SwiftUI

struct GameView: View {
    nonisolated static let space = "game"

    @State private var viewModel: GameViewModel
    @State private var boardFrame: CGRect = .zero
    @Environment(AppRouter.self) private var router
    @Environment(\.scenePhase) private var scenePhase

    init(configuration: GameConfiguration, dependencies: FeatureDependencies) {
        _viewModel = State(initialValue: GameViewModel(configuration: configuration, dependencies: dependencies))
    }

    private var table: TableSurface { viewModel.configuration.table }

    var body: some View {
        ZStack {
            table.color.ignoresSafeArea()
            switch viewModel.phase {
            case .loading:
                loading
            case .failed:
                ErrorStateView(message: L10n.Game.loadFailed, tint: table.content) {
                    Task { await viewModel.retry() }
                }
                .overlay(alignment: .topLeading) { closeButton.padding(PZSpacing.l) }
            case .playing:
                playing
            case let .completed(summary):
                CompletionView(
                    puzzle: viewModel.configuration.puzzle,
                    image: viewModel.sourceImage,
                    summary: summary,
                    table: table,
                    nextTitle: viewModel.configuration.isEventLevel ? L10n.Done.backToEvent : L10n.Done.next,
                    savedNote: viewModel.configuration.isEventLevel ? nil : L10n.Done.saved,
                    onNext: { router.closeGame(showLibrary: !viewModel.configuration.isEventLevel) },
                    onClose: { router.closeGame() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: viewModel.phase)
        .coordinateSpace(.named(Self.space))
        .overlay { DraggedPieceOverlay(viewModel: viewModel, boardWidth: boardFrame.width) }
        .preferredColorScheme(table.isLight ? .light : .dark)
        .sensoryFeedback(.success, trigger: viewModel.snapCount)
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.missCount)
        .task { await viewModel.load() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { viewModel.resume() } else { viewModel.pause() }
        }
    }

    private var loading: some View {
        VStack(spacing: PZSpacing.l) {
            ProgressView().tint(table.content)
            Text(L10n.Game.loading)
                .font(PZFont.callout)
                .foregroundStyle(table.contentMuted)
        }
    }

    private var playing: some View {
        VStack(spacing: 0) {
            GameHUD(viewModel: viewModel, table: table, onClose: close)
            BoardView(viewModel: viewModel, boardFrame: boardFrame)
                .onGeometryChange(for: CGRect.self) { proxy in
                    proxy.frame(in: .named(Self.space))
                } action: { frame in
                    boardFrame = frame
                }
                .padding(.horizontal, PZSpacing.l)
                .padding(.top, PZSpacing.l)
                .frame(maxWidth: 720, maxHeight: .infinity)
            GameToolbar(viewModel: viewModel, table: table)
            PieceTrayView(viewModel: viewModel, table: table, boardFrame: boardFrame)
        }
    }

    private var closeButton: some View {
        Button(L10n.Common.close, systemImage: "xmark", action: close)
            .labelStyle(.iconOnly)
            .buttonStyle(.pzCircle(background: table.raised, foreground: table.content))
    }

    private func close() {
        Task {
            await viewModel.prepareToClose()
            router.closeGame()
        }
    }
}

/// The piece under the finger, drawn at board scale so the player sees the exact fit.
private struct DraggedPieceOverlay: View {
    let viewModel: GameViewModel
    let boardWidth: CGFloat

    var body: some View {
        if let piece = viewModel.draggingPiece,
           let image = viewModel.image(for: piece),
           let size = viewModel.pieceSize(piece, boardWidth: boardWidth) {
            Image(decorative: image, scale: 1)
                .resizable()
                .frame(width: size.width, height: size.height)
                .rotationEffect(.degrees(Double(viewModel.rotation(of: piece)) * 90))
                .shadow(color: .black.opacity(0.35), radius: 10, y: 8)
                .position(
                    x: viewModel.dragLocation.x + viewModel.dragOffset.width,
                    y: viewModel.dragLocation.y + viewModel.dragOffset.height
                )
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

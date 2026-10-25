import PuzzliumDesignSystem
import PuzzliumDomain
import PuzzliumEngine
import SwiftUI

struct PieceTrayView: View {
    let viewModel: GameViewModel
    let table: TableSurface
    let boardFrame: CGRect

    private static let cell: CGFloat = 64
    private let rows = [GridItem(.fixed(cell), spacing: PZSpacing.s), GridItem(.fixed(cell))]

    var body: some View {
        VStack(alignment: .leading, spacing: PZSpacing.m) {
            HStack(spacing: PZSpacing.s) {
                filterChip(.all, title: L10n.Game.filterAll(viewModel.trayCount(.all)))
                filterChip(.edges, title: L10n.Game.filterEdges(viewModel.trayCount(.edges)))
                filterChip(.inner, title: L10n.Game.filterInner(viewModel.trayCount(.inner)))
            }
            .padding(.horizontal, PZSpacing.l)

            ScrollView(.horizontal) {
                LazyHGrid(rows: rows, spacing: PZSpacing.s) {
                    ForEach(viewModel.trayPieces, id: \.self) { piece in
                        TrayPiece(viewModel: viewModel, piece: piece, size: Self.cell, boardFrame: boardFrame)
                    }
                }
                .padding(.horizontal, PZSpacing.l)
            }
            .scrollIndicators(.hidden)
            .frame(height: Self.cell * 2 + PZSpacing.s)
            .overlay {
                if viewModel.trayPieces.isEmpty {
                    Text(L10n.Game.trayEmpty)
                        .font(PZFont.callout)
                        .foregroundStyle(table.contentMuted)
                }
            }
        }
        .padding(.top, PZSpacing.l)
        .padding(.bottom, PZSpacing.s)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: PZRadius.xl, topTrailingRadius: PZRadius.xl, style: .continuous)
                .fill(table.tray)
                .ignoresSafeArea(edges: .bottom)
        )
        .animation(.snappy(duration: 0.25), value: viewModel.trayPieces)
    }

    private func filterChip(_ filter: TrayFilter, title: String) -> some View {
        PZChip(title, isSelected: viewModel.trayFilter == filter, tone: table.isLight ? .light : .onFelt) {
            viewModel.trayFilter = filter
        }
    }
}

private struct TrayPiece: View {
    let viewModel: GameViewModel
    let piece: Int
    let size: CGFloat
    let boardFrame: CGRect

    var body: some View {
        let isDragging = viewModel.draggingPiece == piece
        Group {
            if let image = viewModel.image(for: piece) {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(.degrees(Double(viewModel.rotation(of: piece)) * 90))
                    .animation(.snappy(duration: 0.2), value: viewModel.rotation(of: piece))
            } else {
                Color.clear
            }
        }
        .frame(width: size, height: size)
        .opacity(isDragging ? 0.2 : 1)
        .contentShape(Rectangle())
        .onTapGesture { viewModel.rotate(piece) }
        .gesture(dragGesture)
        .accessibilityElement()
        .accessibilityLabel(L10n.Game.piece(piece + 1))
        .accessibilityIdentifier("game.trayPiece")
        .accessibilityAction(named: L10n.Game.placePiece) { viewModel.placeAccessibly(piece) }
        .accessibilityAction(named: L10n.Game.rotatePiece) { viewModel.rotate(piece) }
    }

    /// Short press then drag: horizontal swipes still scroll the tray.
    private var dragGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.12)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named(GameView.space)))
            .onChanged { value in
                if case let .second(true, drag?) = value {
                    viewModel.drag(piece, to: drag.location)
                }
            }
            .onEnded { value in
                if case .second(true, _?) = value {
                    viewModel.endDrag(in: boardFrame)
                } else {
                    viewModel.cancelDrag()
                }
            }
    }
}

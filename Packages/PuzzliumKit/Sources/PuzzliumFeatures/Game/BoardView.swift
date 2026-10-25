import PuzzliumDesignSystem
import PuzzliumEngine
import SwiftUI

struct BoardView: View {
    let viewModel: GameViewModel
    let boardFrame: CGRect

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
        ZStack {
            shape.fill(.black.opacity(0.18))
            if viewModel.showsPreview, let source = viewModel.sourceImage {
                Image(decorative: source, scale: 1)
                    .resizable()
                    .opacity(0.22)
                    .transition(.opacity)
            }
            if let outline = viewModel.slotOutline {
                SlotOutlineShape(unitPath: outline)
                    .stroke(.white.opacity(0.14), lineWidth: 0.75)
            }
            if let composite = viewModel.compositeImage {
                Image(decorative: composite, scale: 1)
                    .resizable()
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(shape)
        .overlay(shape.strokeBorder(.white.opacity(0.2), lineWidth: 1))
        .animation(.easeOut(duration: 0.2), value: viewModel.showsPreview)
        .accessibilityElement()
        .accessibilityLabel(L10n.Game.board)
        .accessibilityIdentifier("game.board")
        .accessibilityValue(L10n.Game.progress(viewModel.board?.placedCount ?? 0, viewModel.board?.totalCount ?? 0))
        // Above the clip so tabs of pieces near the edge stay whole.
        .overlay {
            GeometryReader { proxy in
                ForEach(viewModel.loosePieces, id: \.piece) { loose in
                    LoosePieceView(viewModel: viewModel, loose: loose, boardSize: proxy.size, boardFrame: boardFrame)
                }
            }
        }
    }
}

/// A piece lying on the board away from its slot: drag to move it, tap to rotate.
private struct LoosePieceView: View {
    let viewModel: GameViewModel
    let loose: LoosePiece
    let boardSize: CGSize
    let boardFrame: CGRect

    var body: some View {
        let piece = loose.piece
        if let image = viewModel.image(for: piece), let size = viewModel.pieceSize(piece, boardWidth: boardSize.width) {
            // Only the cell in the middle of the padded image takes touches, not the transparent margin.
            let inset = size.width * PieceGeometry.marginRatio / (1 + 2 * PieceGeometry.marginRatio)
            Image(decorative: image, scale: 1)
                .resizable()
                .frame(width: size.width, height: size.height)
                .rotationEffect(.degrees(Double(viewModel.rotation(of: piece)) * 90))
                .animation(.snappy(duration: 0.2), value: viewModel.rotation(of: piece))
                .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
                .opacity(viewModel.draggingPiece == piece ? 0 : 1)
                .contentShape(Rectangle().inset(by: inset))
                .position(x: loose.center.x * boardSize.width, y: loose.center.y * boardSize.height)
                .onTapGesture { viewModel.rotate(piece) }
                .gesture(dragGesture)
                .accessibilityElement()
                .accessibilityLabel(L10n.Game.piece(piece + 1))
                .accessibilityIdentifier("game.loosePiece")
                .accessibilityAction(named: L10n.Game.placePiece) { viewModel.placeAccessibly(piece) }
                .accessibilityAction(named: L10n.Game.rotatePiece) { viewModel.rotate(piece) }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .named(GameView.space))
            .onChanged { value in
                // Keep the grab point under the finger instead of jumping by the tray lift.
                let center = CGPoint(
                    x: boardFrame.minX + loose.center.x * boardFrame.width,
                    y: boardFrame.minY + loose.center.y * boardFrame.height
                )
                let offset = CGSize(width: center.x - value.startLocation.x, height: center.y - value.startLocation.y)
                viewModel.drag(loose.piece, to: value.location, offset: offset)
            }
            .onEnded { _ in viewModel.endDrag(in: boardFrame) }
    }
}

/// Every slot outline, built once in unit space and scaled to the board.
private struct SlotOutlineShape: Shape {
    let unitPath: Path

    func path(in rect: CGRect) -> Path {
        unitPath.applying(
            CGAffineTransform(translationX: rect.minX, y: rect.minY).scaledBy(x: rect.width, y: rect.height)
        )
    }
}

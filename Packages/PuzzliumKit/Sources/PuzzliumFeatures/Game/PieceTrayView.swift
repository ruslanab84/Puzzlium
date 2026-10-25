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
            .scrollDisabled(viewModel.draggingPiece != nil)
            .frame(height: Self.cell * 2 + PZSpacing.s)
            .overlay {
                if viewModel.trayPieces.isEmpty {
                    // Loose pieces still need placing, so "every piece is placed" would be misleading.
                    let loose = viewModel.loosePieces.count
                    Text(loose > 0 ? L10n.Game.looseLeft(loose) : L10n.Game.trayEmpty)
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
        .modifier(LiftGesture(fallback: dragGesture, onChanged: { viewModel.drag(piece, to: $0) }, onEnded: endLift))
        .accessibilityElement()
        .accessibilityLabel(L10n.Game.piece(piece + 1))
        .accessibilityIdentifier("game.trayPiece")
        .accessibilityAction(named: L10n.Game.placePiece) { viewModel.placeAccessibly(piece) }
        .accessibilityAction(named: L10n.Game.rotatePiece) { viewModel.rotate(piece) }
    }

    private func endLift(dropped: Bool) {
        if dropped { viewModel.endDrag(in: boardFrame) } else { viewModel.cancelDrag() }
    }

    /// iOS 17 path. On iOS 18+ SwiftUI gestures run on UIKit and this one swallows
    /// the ScrollView's pan, so `LiftGesture` swaps in a direction-aware UIKit pan there.
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

/// Vertical drag lifts a piece, horizontal swipe scrolls the tray. Direction, not
/// press timing, decides: a finger that rests a moment before swiping still scrolls.
private struct LiftGesture<Fallback: Gesture>: ViewModifier {
    let fallback: Fallback
    let onChanged: (CGPoint) -> Void
    let onEnded: (_ dropped: Bool) -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.gesture(VerticalPan(onChanged: onChanged, onEnded: onEnded))
        } else {
            content.gesture(fallback)
        }
    }
}

@available(iOS 18.0, *)
private struct VerticalPan: UIGestureRecognizerRepresentable {
    let onChanged: (CGPoint) -> Void
    let onEnded: (_ dropped: Bool) -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let recognizer = UIPanGestureRecognizer()
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        switch recognizer.state {
        case .began, .changed: onChanged(context.converter.location(in: .named(GameView.space)))
        case .ended: onEnded(true)
        case .cancelled, .failed: onEnded(false)
        default: break
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
            guard let pan = recognizer as? UIPanGestureRecognizer else { return true }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.y) > abs(velocity.x)
        }
    }
}

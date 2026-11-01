import PuzzliumDesignSystem
import PuzzliumDomain
import PuzzliumEngine
import SwiftUI

struct PieceTrayView: View {
    let viewModel: GameViewModel
    let table: TableSurface
    let boardFrame: CGRect
    /// `.horizontal`: a two-row strip under the board. `.vertical`: a side column next to it.
    var axis: Axis = .horizontal
    var cell: CGFloat = 64

    @Namespace private var chipNamespace

    var body: some View {
        VStack(alignment: .leading, spacing: PZSpacing.m) {
            HStack(spacing: PZSpacing.s) {
                filterChip(.all, title: L10n.Game.filterAllLabel, label: L10n.Game.filterAll)
                filterChip(.edges, title: L10n.Game.filterEdgesLabel, label: L10n.Game.filterEdges)
                filterChip(.inner, title: L10n.Game.filterInnerLabel, label: L10n.Game.filterInner)
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.7), value: viewModel.trayFilter)
            .padding(.horizontal, PZSpacing.l)

            ScrollView(axis == .horizontal ? .horizontal : .vertical) {
                if axis == .horizontal {
                    LazyHGrid(rows: [GridItem(.fixed(cell), spacing: PZSpacing.s), GridItem(.fixed(cell))], spacing: PZSpacing.s) {
                        pieces
                    }
                    .padding(.horizontal, PZSpacing.l)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: cell), spacing: PZSpacing.s)], spacing: PZSpacing.s) {
                        pieces
                    }
                    .padding(.horizontal, PZSpacing.l)
                }
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(viewModel.draggingPiece != nil)
            .frame(height: axis == .horizontal ? cell * 2 + PZSpacing.s : nil)
            .frame(maxHeight: axis == .vertical ? .infinity : nil)
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
        .background {
            if axis == .horizontal {
                UnevenRoundedRectangle(topLeadingRadius: PZRadius.xl, topTrailingRadius: PZRadius.xl, style: .continuous)
                    .fill(table.tray)
                    .ignoresSafeArea(edges: .bottom)
            } else {
                UnevenRoundedRectangle(topLeadingRadius: PZRadius.xl, bottomLeadingRadius: PZRadius.xl, style: .continuous)
                    .fill(table.tray)
                    .ignoresSafeArea(edges: [.vertical, .trailing])
            }
        }
        .animation(.snappy(duration: 0.25), value: viewModel.trayPieces)
    }

    private var pieces: some View {
        ForEach(viewModel.trayPieces, id: \.self) { piece in
            TrayPiece(viewModel: viewModel, piece: piece, size: cell, boardFrame: boardFrame, scrollAxis: axis)
        }
    }

    private func filterChip(_ filter: TrayFilter, title: String, label: (Int) -> String) -> some View {
        let count = viewModel.trayCount(filter)
        let isSelected = viewModel.trayFilter == filter
        return Button {
            viewModel.trayFilter = filter
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .font(PZFont.callout.weight(.bold))
                    .minimumScaleFactor(0.7)
                Text(verbatim: "\(count)")
                    .font(PZFont.number(.footnote))
                    .contentTransition(.numericText(value: Double(count)))
                    .fixedSize()
                    .padding(.horizontal, 7)
                    .frame(minWidth: 24, minHeight: 22)
                    .background(isSelected ? Color.black.opacity(0.16) : table.raised, in: Capsule())
                    .animation(.snappy, value: count)
            }
            .lineLimit(1)
            .foregroundStyle(isSelected ? Color(hex: 0x2A1C08) : table.content)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, minHeight: 40)
            .contentShape(Capsule())
            .background {
                if isSelected {
                    Capsule()
                        .fill(PZColor.amber)
                        .shadow(color: PZColor.amber.opacity(0.45), radius: 8, y: 2)
                        .matchedGeometryEffect(id: "filter", in: chipNamespace)
                } else {
                    Capsule().fill(table.raised)
                }
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected) { _, selected in selected }
        .accessibilityLabel(label(count))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct TrayPiece: View {
    let viewModel: GameViewModel
    let piece: Int
    let size: CGFloat
    let boardFrame: CGRect
    let scrollAxis: Axis

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
        .modifier(LiftGesture(scrollAxis: scrollAxis, fallback: dragGesture, onChanged: { viewModel.drag(piece, to: $0) }, onEnded: endLift))
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

/// A drag across the tray's scroll axis lifts a piece, a swipe along it scrolls the tray.
/// Direction, not press timing, decides: a finger that rests a moment before swiping still scrolls.
private struct LiftGesture<Fallback: Gesture>: ViewModifier {
    let scrollAxis: Axis
    let fallback: Fallback
    let onChanged: (CGPoint) -> Void
    let onEnded: (_ dropped: Bool) -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.gesture(CrossAxisPan(scrollAxis: scrollAxis, onChanged: onChanged, onEnded: onEnded))
        } else {
            content.gesture(fallback)
        }
    }
}

@available(iOS 18.0, *)
private struct CrossAxisPan: UIGestureRecognizerRepresentable {
    let scrollAxis: Axis
    let onChanged: (CGPoint) -> Void
    let onEnded: (_ dropped: Bool) -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator(scrollAxis: scrollAxis) }

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
        let scrollAxis: Axis

        init(scrollAxis: Axis) {
            self.scrollAxis = scrollAxis
        }

        func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
            guard let pan = recognizer as? UIPanGestureRecognizer else { return true }
            let velocity = pan.velocity(in: pan.view)
            return scrollAxis == .horizontal ? abs(velocity.y) > abs(velocity.x) : abs(velocity.x) > abs(velocity.y)
        }
    }
}

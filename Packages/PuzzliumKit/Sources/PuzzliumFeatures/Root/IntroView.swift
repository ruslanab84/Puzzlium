import PuzzliumDesignSystem
import SwiftUI

/// 3-second launch intro: the app-icon piece assembles from four fragments, snaps,
/// the wordmark rises in, a shine sweeps across, then everything clears to reveal the app.
struct IntroView: View {
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var assembled = false
    @State private var snapped = false
    @State private var pulse = false
    @State private var wordmark = false
    @State private var shine = false
    @State private var exiting = false

    private static let title = Array("Puzzlium")
    private static let pieceSize: CGFloat = 200
    /// Each fragment's start offset (in piece sizes) and spin, flying in from its own corner.
    private static let fragments: [(UnitPoint, CGSize, Double)] = [
        (.topLeading, CGSize(width: -0.9, height: -1.1), -24),
        (.topTrailing, CGSize(width: 1.0, height: -0.9), 18),
        (.bottomLeading, CGSize(width: -1.0, height: 0.9), 20),
        (.bottomTrailing, CGSize(width: 0.9, height: 1.1), -16),
    ]

    var body: some View {
        ZStack {
            PZColor.felt.ignoresSafeArea()

            VStack(spacing: PZSpacing.xxl) {
                piece
                wordmarkView
            }
            .scaleEffect(exiting ? 0.92 : 1)
            .opacity(exiting ? 0 : 1)
        }
        .opacity(exiting ? 0 : 1)
        .sensoryFeedback(.impact(weight: .light), trigger: snapped)
        .accessibilityHidden(true)
        .task { await play() }
    }

    private var piece: some View {
        let size = Self.pieceSize
        return ZStack {
            // Secondary layer: the shadow lands a beat after the fragments, as in the app icon.
            IntroPieceShape()
                .fill(PZColor.feltDeep)
                .offset(x: snapped ? size * 0.025 : 0, y: snapped ? size * 0.06 : 0)
                .opacity(snapped ? 1 : 0)

            ForEach(Self.fragments.indices, id: \.self) { index in
                let (corner, start, spin) = Self.fragments[index]
                IntroPieceShape()
                    .fill(PZColor.amber)
                    .clipShape(QuadrantShape(corner: corner))
                    .offset(assembled ? .zero : CGSize(width: start.width * size, height: start.height * size))
                    .rotationEffect(.degrees(assembled ? 0 : spin))
                    .scaleEffect(assembled ? 1 : 0.8)
                    .opacity(assembled ? 1 : 0)
                    .animation(
                        .spring(duration: 0.55, bounce: 0.3).delay(Double(index) * 0.07),
                        value: assembled
                    )
            }

            // Once snapped, a whole piece covers the anti-aliased seams between fragments.
            IntroPieceShape()
                .fill(PZColor.amber)
                .opacity(snapped ? 1 : 0)

            // Ambient layer: one soft shine across the finished piece.
            LinearGradient(
                colors: [.clear, .white.opacity(0.45), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: size * 0.45)
            .rotationEffect(.degrees(20))
            .offset(x: shine ? size : -size)
            .mask(IntroPieceShape())
        }
        .frame(width: size, height: size)
        .scaleEffect(pulse ? 1.06 : 1)
    }

    private var wordmarkView: some View {
        HStack(spacing: 0) {
            ForEach(Self.title.indices, id: \.self) { index in
                Text(String(Self.title[index]))
                    .offset(y: wordmark ? 0 : 18)
                    .opacity(wordmark ? 1 : 0)
                    .animation(
                        .spring(duration: 0.45, bounce: 0.35).delay(Double(index) * 0.035),
                        value: wordmark
                    )
            }
        }
        .font(.system(size: 40, weight: .heavy, design: .rounded))
        .foregroundStyle(PZColor.onFelt)
    }

    private func play() async {
        if reduceMotion {
            var instant = Transaction()
            instant.disablesAnimations = true
            withTransaction(instant) {
                assembled = true
                snapped = true
                wordmark = true
            }
            await pause(1.2)
        } else {
            await pause(0.15)
            assembled = true
            await pause(0.75)
            withAnimation(.easeOut(duration: 0.12)) {
                snapped = true
                pulse = true
            }
            await pause(0.12)
            withAnimation(.spring(duration: 0.35, bounce: 0.5)) { pulse = false }
            wordmark = true
            await pause(0.3)
            withAnimation(.easeInOut(duration: 0.8)) { shine = true }
            await pause(1.3)
        }
        withAnimation(.easeIn(duration: 0.35)) { exiting = true }
        await pause(0.35)
        onFinish()
    }

    private func pause(_ seconds: Double) async {
        try? await Task.sleep(for: .seconds(seconds))
    }
}

/// The app-icon jigsaw piece: knobs out on top and right, sockets on left and bottom.
/// Proportions are measured from AppIcon.png; the body fills the middle 2/3 of the rect.
private struct IntroPieceShape: Shape {
    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height) / 1.5
        let body = CGRect(x: rect.midX - side / 2, y: rect.midY - side / 2, width: side, height: side)
        let headW = side * 0.22, headH = side * 0.17
        let reach = side * 0.164
        let neck = side * 0.13

        func knob(edge: CGPoint, outward: CGVector) -> Path {
            let center = CGPoint(x: edge.x + outward.dx * reach, y: edge.y + outward.dy * reach)
            let vertical = outward.dx == 0
            var path = Path(ellipseIn: CGRect(
                x: center.x - (vertical ? headW : headH) / 2,
                y: center.y - (vertical ? headH : headW) / 2,
                width: vertical ? headW : headH,
                height: vertical ? headH : headW
            ))
            path.addRect(CGRect(
                x: min(edge.x, center.x) - (vertical ? neck / 2 : 0),
                y: min(edge.y, center.y) - (vertical ? 0 : neck / 2),
                width: vertical ? neck : abs(center.x - edge.x),
                height: vertical ? abs(center.y - edge.y) : neck
            ))
            return path
        }

        return Path(body)
            .union(knob(edge: CGPoint(x: body.midX, y: body.minY), outward: CGVector(dx: 0, dy: -1)))
            .union(knob(edge: CGPoint(x: body.maxX, y: body.midY), outward: CGVector(dx: 1, dy: 0)))
            .subtracting(knob(edge: CGPoint(x: body.minX, y: body.midY), outward: CGVector(dx: 1, dy: 0)))
            .subtracting(knob(edge: CGPoint(x: body.midX, y: body.maxY), outward: CGVector(dx: 0, dy: -1)))
    }
}

/// One quarter of the rect around its center, extended past the edges so knobs stay inside.
private struct QuadrantShape: Shape {
    let corner: UnitPoint

    func path(in rect: CGRect) -> Path {
        let pad = rect.width
        let x = corner.x < 0.5 ? rect.minX - pad : rect.midX
        let y = corner.y < 0.5 ? rect.minY - pad : rect.midY
        return Path(CGRect(x: x, y: y, width: rect.width / 2 + pad, height: rect.height / 2 + pad))
    }
}

#Preview {
    IntroView {}
}

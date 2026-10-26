import PuzzliumDesignSystem
import PuzzliumDomain
import SwiftUI

struct CompletionView: View {
    let puzzle: Puzzle
    let image: CGImage?
    let summary: CompletionSummary
    let table: TableSurface
    var nextTitle = L10n.Done.next
    /// Event levels are not listed in My puzzles, so they pass `nil`.
    var savedNote: String? = L10n.Done.saved
    let onNext: () -> Void
    let onClose: () -> Void

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: PZSpacing.xl) {
            HStack {
                Spacer()
                Button(L10n.Common.close, systemImage: "xmark", action: onClose)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.pzCircle(background: table.raised, foreground: table.content))
            }

            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .padding(10)
                    .background(.white, in: RoundedRectangle(cornerRadius: 8))
                    .rotationEffect(.degrees(appeared || reduceMotion ? -2 : 12))
                    .scaleEffect(appeared || reduceMotion ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 18)
                    .background { if !reduceMotion { CelebrationRays(isOn: appeared) } }
                    .frame(maxWidth: 320)
                    .accessibilityHidden(true)
            }

            VStack(spacing: PZSpacing.s) {
                HStack(spacing: 6) {
                    ForEach(0..<3) { index in
                        CelebrationStar(index: index, isOn: appeared, reduceMotion: reduceMotion)
                    }
                }
                .accessibilityHidden(true)
                Text(L10n.Done.badge.uppercased())
                    .font(PZFont.eyebrow)
                    .tracking(1)
                    .foregroundStyle(PZColor.amber)
                    .scaleEffect(appeared || reduceMotion ? 1 : 0.4)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.45, dampingFraction: 0.5).delay(0.35), value: appeared)
                Text(puzzle.title)
                    .font(PZFont.largeTitle)
                    .foregroundStyle(table.content)
                    .multilineTextAlignment(.center)
                if let savedNote {
                    Text(savedNote)
                        .font(PZFont.callout)
                        .foregroundStyle(table.contentMuted)
                }
            }

            HStack(spacing: PZSpacing.s) {
                stat(L10n.Done.time, TimeText.clock(summary.duration), order: 0)
                stat(L10n.Done.pieces, String(summary.pieceCount), order: 1)
                stat(L10n.Done.streak, L10n.Done.streakValue(summary.streak), order: 2)
            }

            Spacer(minLength: 0)

            VStack(spacing: PZSpacing.m) {
                Button(nextTitle, action: onNext)
                    .buttonStyle(.pzPrimary(background: PZColor.amber, foreground: Color(hex: 0x18201D)))
                if let image {
                    let shareImage = Image(decorative: image, scale: 1)
                    ShareLink(item: shareImage, preview: SharePreview(puzzle.title, image: shareImage)) {
                        Label(L10n.Done.share, systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(PZOutlineButtonStyle(tint: table.content))
                }
            }
        }
        .padding(.horizontal, PZSpacing.xl)
        .padding(.vertical, PZSpacing.l)
        .frame(maxWidth: 560)
        .overlay {
            if !reduceMotion {
                ConfettiView().ignoresSafeArea()
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.62), value: appeared)
        .onAppear { appeared = true }
    }

    private func stat(_ title: String, _ value: String, order: Int) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(PZFont.caption)
                .foregroundStyle(table.contentMuted)
            Text(value)
                .font(PZFont.number(.title3))
                .foregroundStyle(table.content)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 64)
        .background(table.raised, in: RoundedRectangle(cornerRadius: PZRadius.m, style: .continuous))
        .offset(y: appeared || reduceMotion ? 0 : 40)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.55 + Double(order) * 0.1), value: appeared)
        .accessibilityElement(children: .combine)
    }
}

/// Three stars that pop in one after another above the "Puzzle complete" badge.
private struct CelebrationStar: View {
    let index: Int
    let isOn: Bool
    let reduceMotion: Bool

    var body: some View {
        Image(systemName: "star.fill")
            .font(.system(size: index == 1 ? 34 : 26, weight: .bold))
            .foregroundStyle(PZColor.amber)
            .shadow(color: PZColor.amber.opacity(0.6), radius: 8)
            .offset(y: index == 1 ? -6 : 0)
            .scaleEffect(isOn || reduceMotion ? 1 : 0.01)
            .rotationEffect(.degrees(isOn || reduceMotion ? 0 : -90))
            .opacity(isOn ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.45).delay(0.25 + Double(index) * 0.12), value: isOn)
    }
}

/// Slowly turning sunburst glow behind the finished picture.
private struct CelebrationRays: View {
    let isOn: Bool
    @State private var spin = false

    var body: some View {
        AngularGradient(
            gradient: Gradient(colors: Array(repeating: [PZColor.amber.opacity(0.55), .clear], count: 12).flatMap { $0 }),
            center: .center
        )
        .mask(RadialGradient(colors: [.white, .clear], center: .center, startRadius: 40, endRadius: 260))
        .frame(width: 560, height: 560)
        .rotationEffect(.degrees(spin ? 360 : 0))
        .scaleEffect(isOn ? 1 : 0.3)
        .opacity(isOn ? 1 : 0)
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.linear(duration: 24).repeatForever(autoreverses: false)) { spin = true }
        }
    }
}

/// Two confetti bursts from the bottom corners that fall back under gravity and fade out.
private struct ConfettiView: View {
    private struct Particle {
        let fromLeft: Bool
        let angle: Double
        let speed: Double
        let spin: Double
        let size: CGSize
        let color: Color
        let delay: Double
    }

    private static let colors: [Color] = [PZColor.amber, Color(hex: 0xE4572E), Color(hex: 0x4FB286), Color(hex: 0x3D8BD9), Color(hex: 0xF2E8CF), Color(hex: 0xC879D8)]
    private static let lifetime = 3.6

    @State private var start = Date.now
    @State private var isDone = false
    @State private var particles: [Particle] = (0..<90).map { index in
        Particle(
            fromLeft: index.isMultiple(of: 2),
            angle: .random(in: 55...80) * .pi / 180,
            speed: .random(in: 700...1100),
            spin: .random(in: -9...9),
            size: CGSize(width: .random(in: 6...11), height: .random(in: 10...16)),
            color: colors[index % colors.count],
            delay: .random(in: 0...0.25)
        )
    }

    var body: some View {
        TimelineView(.animation(paused: isDone)) { context in
            Canvas { canvas, size in
                let elapsed = context.date.timeIntervalSince(start)
                let gravity = 1400.0
                for particle in particles {
                    let t = elapsed - particle.delay
                    guard t > 0 else { continue }
                    let direction = particle.fromLeft ? 1.0 : -1.0
                    let x = (particle.fromLeft ? 0 : size.width) + direction * cos(particle.angle) * particle.speed * t * 0.55
                    let y = size.height + 20 - sin(particle.angle) * particle.speed * t + 0.5 * gravity * t * t
                    let fade = min(1, max(0, (Self.lifetime - elapsed) / 0.8))
                    guard fade > 0 else { continue }
                    var piece = canvas
                    piece.opacity = fade
                    piece.translateBy(x: x, y: y)
                    piece.rotate(by: .radians(particle.spin * t))
                    // Flip on one axis to fake a tumbling paper strip.
                    piece.scaleBy(x: 1, y: abs(cos(particle.spin * t * 0.7)) * 0.8 + 0.2)
                    let rect = CGRect(origin: CGPoint(x: -particle.size.width / 2, y: -particle.size.height / 2), size: particle.size)
                    piece.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(particle.color))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .opacity(isDone ? 0 : 1)
        .task {
            start = .now
            try? await Task.sleep(for: .seconds(Self.lifetime))
            isDone = true
        }
    }
}

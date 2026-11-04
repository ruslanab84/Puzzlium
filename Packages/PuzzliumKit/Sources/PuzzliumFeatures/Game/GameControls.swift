import PuzzliumDesignSystem
import PuzzliumDomain
import SwiftUI

struct GameHUD: View {
    let viewModel: GameViewModel
    let table: TableSurface
    let onClose: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let placed = viewModel.board?.placedCount ?? 0
        let total = viewModel.board?.totalCount ?? 0

        VStack(spacing: PZSpacing.m) {
            HStack {
                Button(L10n.Common.close, systemImage: "xmark", action: onClose)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.pzCircle(background: table.raised, foreground: table.content))
                    .accessibilityIdentifier("game.close")
                Spacer()
                VStack(spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(verbatim: "\(placed)")
                            .font(.system(.largeTitle, design: .rounded, weight: .black))
                            .foregroundStyle(PZColor.amber)
                            .shadow(color: PZColor.amber.opacity(0.45), radius: 8)
                            .contentTransition(.numericText(value: Double(placed)))
                        Text(verbatim: "/ \(total)")
                            .font(.system(.title3, design: .rounded, weight: .heavy))
                            .foregroundStyle(table.contentMuted)
                    }
                    .monospacedDigit()
                    .animation(.snappy, value: placed)
                    .keyframeAnimator(initialValue: 1.0, trigger: placed) { content, scale in
                        content.scaleEffect(scale)
                    } keyframes: { _ in
                        SpringKeyframe(reduceMotion ? 1 : 1.25, duration: 0.12)
                        SpringKeyframe(1, spring: .bouncy)
                    }
                    HStack(spacing: 6) {
                        Label(viewModel.configuration.puzzle.title, systemImage: "puzzlepiece.fill")
                            .lineLimit(1)
                            .modifier(HUDPill(table: table))
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            Label(TimeText.clock(viewModel.elapsed(at: context.date)), systemImage: "timer")
                                .monospacedDigit()
                                .fixedSize()
                                .modifier(HUDPill(table: table))
                        }
                        .fixedSize()
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(L10n.Game.progress(placed, total))
                Spacer()
                Button(L10n.Game.preview, systemImage: viewModel.showsPreview ? "eye.fill" : "eye.slash", action: viewModel.togglePreview)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.pzCircle(background: table.raised, foreground: table.content))
                    .accessibilityAddTraits(viewModel.showsPreview ? .isSelected : [])
            }
            PZProgressBar(
                value: viewModel.board?.fraction ?? 0,
                tint: PZColor.amber,
                track: table.content.opacity(0.16)
            )
            .animation(.snappy, value: placed)
        }
        .padding(.horizontal, PZSpacing.l)
        .padding(.top, PZSpacing.s)
    }
}

/// Picks the background track, or turns music off; the choice applies right away.
private struct MusicMenu: View {
    let table: TableSurface
    @Bindable private var music = BackgroundMusic.shared

    var body: some View {
        Menu {
            Picker(L10n.Game.music, selection: $music.track) {
                ForEach(BackgroundMusic.Track.allCases) { track in
                    Text(track.title).tag(track)
                }
            }
        } label: {
            Label(L10n.Game.music, systemImage: music.track == .off ? "speaker.slash.fill" : "music.note")
        }
        .menuStyle(.button)
        .labelStyle(.iconOnly)
        .buttonStyle(GameKeyButtonStyle(face: table.raised, edge: .black.opacity(0.28), foreground: table.content, base: table.color))
        .accessibilityValue(music.track.title)
        .accessibilityIdentifier("game.music")
    }
}

private struct HUDPill: ViewModifier {
    let table: TableSurface

    func body(content: Content) -> some View {
        content
            .font(PZFont.caption.weight(.bold))
            .foregroundStyle(table.content)
            .labelStyle(HUDPillLabelStyle())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(table.raised, in: Capsule())
    }
}

private struct HUDPillLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon.foregroundStyle(PZColor.amber)
            configuration.title
        }
    }
}

struct GameToolbar: View {
    let viewModel: GameViewModel
    let table: TableSurface
    @State private var shuffles = 0

    var body: some View {
        HStack(spacing: PZSpacing.s) {
            MusicMenu(table: table)
                .frame(width: 56)

            Button {
                shuffles += 1
                viewModel.shuffleTray()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "shuffle")
                        .symbolEffect(.bounce, value: shuffles)
                    Text(L10n.Game.shuffle)
                }
            }
            .buttonStyle(GameKeyButtonStyle(face: table.raised, edge: .black.opacity(0.28), foreground: table.content, base: table.color))
            .accessibilityIdentifier("game.shuffle")

            Button(action: viewModel.useHint) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .symbolEffect(.bounce, value: viewModel.hintsLeft)
                    Text(L10n.Game.hintLabel)
                    Text(verbatim: "\(viewModel.hintsLeft)")
                        .font(PZFont.number(.footnote))
                        .contentTransition(.numericText(value: Double(viewModel.hintsLeft)))
                        .frame(minWidth: 22, minHeight: 22)
                        .background(.black.opacity(0.18), in: Circle())
                }
                .animation(.snappy, value: viewModel.hintsLeft)
            }
            .buttonStyle(GameKeyButtonStyle(face: PZColor.amber, edge: Color(hex: 0xA8661A), foreground: Color(hex: 0x2A1C08)))
            .disabled(viewModel.hintsLeft == 0)
            .accessibilityLabel(L10n.Game.hint(viewModel.hintsLeft))
            .accessibilityIdentifier("game.hint")
        }
        .padding(.horizontal, PZSpacing.l)
        .padding(.vertical, PZSpacing.m)
        .frame(maxWidth: 720)
    }
}

/// Chunky "game key": a face sitting on a darker edge that sinks in when pressed.
private struct GameKeyButtonStyle: ButtonStyle {
    let face: Color
    let edge: Color
    let foreground: Color
    /// Opaque fill under a translucent face, so the edge below doesn't show through it.
    var base: Color = .clear
    @Environment(\.isEnabled) private var isEnabled

    private let depth: CGFloat = 5

    func makeBody(configuration: Configuration) -> some View {
        let sink = configuration.isPressed ? depth - 1 : 0
        let shape = RoundedRectangle(cornerRadius: PZRadius.s, style: .continuous)
        configuration.label
            .font(PZFont.headline)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(face, in: shape)
            .background(base, in: shape)
            .overlay(shape.strokeBorder(.white.opacity(0.18), lineWidth: 1))
            .offset(y: sink)
            .background(edge, in: shape.offset(y: depth))
            .padding(.bottom, depth)
            .saturation(isEnabled ? 1 : 0)
            .opacity(isEnabled ? 1 : 0.5)
            .animation(.spring(response: 0.18, dampingFraction: 0.55), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

import PuzzliumDesignSystem
import PuzzliumDomain
import SwiftUI

struct GameHUD: View {
    let viewModel: GameViewModel
    let table: TableSurface
    let onClose: () -> Void

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
                VStack(spacing: 2) {
                    Text(verbatim: "\(placed) / \(total)")
                        .font(PZFont.number(.title3))
                        .foregroundStyle(table.content)
                        .contentTransition(.numericText(value: Double(placed)))
                        .animation(.snappy, value: placed)
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(verbatim: "\(viewModel.configuration.puzzle.title) · \(TimeText.clock(viewModel.elapsed(at: context.date)))")
                            .font(PZFont.caption.monospacedDigit())
                            .foregroundStyle(table.contentMuted)
                            .lineLimit(1)
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

struct GameToolbar: View {
    let viewModel: GameViewModel
    let table: TableSurface

    var body: some View {
        HStack(spacing: PZSpacing.s) {
            tool(L10n.Game.shuffle, icon: "shuffle", id: "game.shuffle", action: viewModel.shuffleTray)
            tool(L10n.Game.hint(viewModel.hintsLeft), icon: "lightbulb", id: "game.hint", action: viewModel.useHint)
                .disabled(viewModel.hintsLeft == 0)
        }
        .padding(.horizontal, PZSpacing.l)
        .padding(.vertical, PZSpacing.m)
        .frame(maxWidth: 720)
    }

    private func tool(_ title: String, icon: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(PZFont.footnote.weight(.semibold))
                .foregroundStyle(table.content)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(table.raised, in: RoundedRectangle(cornerRadius: PZRadius.s, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }
}

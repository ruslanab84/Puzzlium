import PuzzliumDesignSystem
import PuzzliumDomain
import StoreKit
import SwiftUI

/// Offer for one category pack, with "all packs" as the bigger option below it.
struct PackPaywallView: View {
    let category: PuzzleCategory
    /// The category's pictures in catalog order; the first few are the free sample.
    let pictures: [Puzzle]
    /// The locked picture that was tapped; offers a rewarded ad for just this one.
    var tapped: Puzzle?
    var onAdUnlock: (Puzzle) -> Void = { _ in }

    @Environment(PackStore.self) private var store
    @Environment(\.ads) private var ads
    @Environment(\.dismiss) private var dismiss
    @State private var adFailed = false

    var body: some View {
        VStack(spacing: PZSpacing.l) {
            collage
            VStack(spacing: PZSpacing.s) {
                Text(L10n.Pack.eyebrow.uppercased())
                    .font(PZFont.eyebrow)
                    .foregroundStyle(PZColor.amber)
                Text(category.title)
                    .font(PZFont.largeTitle)
                    .foregroundStyle(PZColor.onFelt)
                Text(verbatim: "\(L10n.Pack.count(pictures.count)) · \(L10n.Pack.freeNote(PackAccess.freePerCategory))")
                    .font(PZFont.callout)
                    .foregroundStyle(PZColor.onFeltMuted)
                    .multilineTextAlignment(.center)
            }
            Spacer(minLength: 0)
            buttons
        }
        .padding(PZSpacing.xl)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity)
        .background(PZColor.felt)
        .overlay(alignment: .topTrailing) {
            Button(L10n.Common.close, systemImage: "xmark") { dismiss() }
                .labelStyle(.iconOnly)
                .buttonStyle(.pzCircle(background: PZColor.feltDeep, foreground: PZColor.onFelt))
                .padding(PZSpacing.l)
        }
        .disabled(store.isPurchasing)
        .alert(L10n.Pack.adUnavailable, isPresented: $adFailed) {}
        // Purchase, restore or an approved Ask to Buy all land here.
        .onChange(of: store.access.isUnlocked(category)) { _, unlocked in
            if unlocked { dismiss() }
        }
    }

    private var collage: some View {
        let shown = Array(pictures.dropFirst(PackAccess.freePerCategory).prefix(4))
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: PZSpacing.s), GridItem(.flexible())], spacing: PZSpacing.s) {
            ForEach(shown) { puzzle in
                PuzzleArtView(source: puzzle.image, pixelSize: 400)
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: PZRadius.m, style: .continuous))
            }
        }
        .padding(.top, PZSpacing.xxl)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var buttons: some View {
        VStack(spacing: PZSpacing.m) {
            if let pack = store.product(for: category) {
                Button { buy(pack) } label: {
                    HStack {
                        Text(L10n.Pack.buy)
                        Spacer()
                        Text(pack.displayPrice)
                    }
                }
                .buttonStyle(.pzPrimary(background: PZColor.amber, foreground: Color(hex: 0x18201D)))
            }
            if let all = store.allPacks {
                Button { buy(all) } label: {
                    HStack {
                        Text(L10n.Pack.buyAll)
                        Spacer()
                        Text(all.displayPrice)
                    }
                    .padding(.horizontal, PZSpacing.xl)
                }
                .buttonStyle(PZOutlineButtonStyle())
                Text(L10n.Pack.allNote)
                    .font(PZFont.caption)
                    .foregroundStyle(PZColor.onFeltMuted)
            }
            if let tapped, let ads {
                Button(L10n.Pack.watchAd, systemImage: "play.rectangle") {
                    Task {
                        guard await ads.showRewarded() else { adFailed = true; return }
                        store.unlockWithAd(tapped.id)
                        onAdUnlock(tapped)
                        dismiss()
                    }
                }
                .font(PZFont.callout.weight(.semibold))
                .foregroundStyle(PZColor.amber)
                .frame(minHeight: 44)
            }
            if store.products.isEmpty {
                Text(L10n.Pack.unavailable)
                    .font(PZFont.callout)
                    .foregroundStyle(PZColor.onFeltMuted)
            }
            Button(L10n.Pack.restore) { Task { await store.restore() } }
                .font(PZFont.footnote.weight(.semibold))
                .foregroundStyle(PZColor.onFelt)
                .frame(minHeight: 44)
        }
        .overlay {
            if store.isPurchasing { ProgressView().tint(PZColor.onFelt) }
        }
    }

    private func buy(_ product: Product) {
        Task { await store.purchase(product) }
    }
}

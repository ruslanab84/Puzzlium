import PuzzliumDesignSystem
import PhotosUI
import PuzzliumDomain
import SwiftUI

struct LibraryView: View {
    @State private var viewModel: LibraryViewModel
    @Environment(AppRouter.self) private var router
    @Environment(PackStore.self) private var packs
    @Environment(\.imageProvider) private var imageProvider
    @State private var paywall: Paywall?
    /// Picture opened by an ad; its setup sheet waits until the paywall is gone.
    @State private var openAfterPaywall: Puzzle?
    @Environment(\.ads) private var ads
    @State private var showsGallery = false
    @State private var showsCamera = false
    @State private var showsPlayground = false
    @State private var galleryItem: PhotosPickerItem?
    @State private var photoFailed = false

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: PZSpacing.m)]

    init(dependencies: FeatureDependencies) {
        _viewModel = State(initialValue: LibraryViewModel(dependencies: dependencies))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: PZSpacing.l) {
                categoryChips
                content
            }
            .padding(.horizontal, PZSpacing.xl)
            .padding(.bottom, PZSpacing.xxl)
        }
        .background(PZColor.ground)
        .navigationTitle(L10n.Library.title)
        .searchable(text: $viewModel.query, prompt: L10n.Library.searchPrompt)
        .task(id: router.contentVersion) { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) { addPhotoMenu }
        }
        .photosPicker(isPresented: $showsGallery, selection: $galleryItem, matching: .images)
        .onChange(of: galleryItem) { _, item in
            guard let item else { return }
            galleryItem = nil
            Task { await addPhoto(try? await item.loadTransferable(type: Data.self)) }
        }
        .fullScreenCover(isPresented: $showsCamera) {
            CameraPicker { data in Task { await addPhoto(data) } }
                .ignoresSafeArea()
        }
        .playgroundSheet(isPresented: $showsPlayground) { data in Task { await addPhoto(data) } }
        .alert(L10n.Library.photoFailed, isPresented: $photoFailed) {}
        .sheet(item: $paywall, onDismiss: {
            if let puzzle = openAfterPaywall { router.openSetup(for: puzzle) }
            openAfterPaywall = nil
        }) { paywall in
            PackPaywallView(
                category: paywall.category,
                pictures: viewModel.items.map(\.puzzle).filter { $0.category == paywall.category },
                tapped: paywall.tapped,
                onAdUnlock: { openAfterPaywall = $0 }
            )
            .environment(packs)
            .environment(\.imageProvider, imageProvider)
            .environment(\.ads, ads)
        }
        .safeAreaInset(edge: .bottom) {
            if let ads, !packs.access.hasPurchased {
                ads.banner()
            }
        }
    }

    private var addPhotoMenu: some View {
        Menu {
            Button(L10n.Library.fromGallery, systemImage: "photo.on.rectangle") { showsGallery = true }
            if CameraPicker.isAvailable {
                Button(L10n.Library.takePhoto, systemImage: "camera") { showsCamera = true }
            }
            PlaygroundMenuButton { showsPlayground = true }
        } label: {
            Label(L10n.Library.addPhoto, systemImage: "plus")
        }
    }

    private func addPhoto(_ data: Data?) async {
        if !(await viewModel.addPhoto(data)) { photoFailed = true }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: PZSpacing.s) {
                categoryCard(title: L10n.Library.all, filter: .all, item: viewModel.items.first)
                ForEach(viewModel.categories, id: \.self) { category in
                    categoryCard(
                        title: category.title,
                        filter: .category(category),
                        item: viewModel.items.first { $0.puzzle.category == category }
                    )
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
    }

    private func categoryCard(title: String, filter: LibraryViewModel.Filter, item: PuzzleEntry?) -> some View {
        let selected = viewModel.filter == filter
        return Button { viewModel.filter = filter } label: {
            ZStack(alignment: .bottomLeading) {
                if let item {
                    PuzzleArtView(source: item.puzzle.image, pixelSize: 240)
                } else {
                    PZColor.felt
                }
                LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .center, endPoint: .bottom)
                Text(title)
                    .font(PZFont.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .padding(PZSpacing.s)
            }
            .frame(width: 132, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: PZRadius.m, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PZRadius.m, style: .continuous)
                    .strokeBorder(selected ? PZColor.felt : .clear, lineWidth: 3)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView().frame(maxWidth: .infinity, minHeight: 300)
        } else if viewModel.loadFailed {
            ErrorStateView(message: L10n.Common.loadFailed) {
                Task { await viewModel.load() }
            }
        } else if viewModel.visibleItems.isEmpty {
            ContentUnavailableView.search(text: viewModel.query)
        } else {
            let locked = packs.access.lockedIDs(in: viewModel.items)
            if case let .category(category) = viewModel.filter {
                packBanner(category, lockedCount: viewModel.visibleItems.filter { locked.contains($0.id) }.count)
            }
            LazyVGrid(columns: columns, spacing: PZSpacing.l) {
                ForEach(viewModel.visibleItems) { item in
                    let isLocked = locked.contains(item.id)
                    Button {
                        if isLocked {
                            paywall = Paywall(category: item.puzzle.category, tapped: item.puzzle)
                        } else {
                            router.openSetup(for: item.puzzle)
                        }
                    } label: {
                        PuzzleGridCard(item: item, isLocked: isLocked)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func packBanner(_ category: PuzzleCategory, lockedCount: Int) -> some View {
        if lockedCount > 0 {
            Button { paywall = Paywall(category: category) } label: {
                HStack(spacing: PZSpacing.m) {
                    Image(systemName: "lock.open.fill")
                        .foregroundStyle(PZColor.amber)
                    Text(L10n.Pack.more(lockedCount))
                        .font(PZFont.callout.weight(.semibold))
                        .foregroundStyle(PZColor.onFelt)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                    Text(packs.product(for: category)?.displayPrice ?? L10n.Pack.unlock)
                        .font(PZFont.callout.weight(.bold))
                        .foregroundStyle(Color(hex: 0x18201D))
                        .padding(.horizontal, PZSpacing.m)
                        .frame(minHeight: 32)
                        .background(PZColor.amber, in: Capsule())
                }
                .padding(PZSpacing.l)
                .background(PZColor.felt, in: RoundedRectangle(cornerRadius: PZRadius.l, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}

/// What the pack sheet offers: the category, plus a single-picture ad unlock when a locked card was tapped.
private struct Paywall: Identifiable {
    let category: PuzzleCategory
    var tapped: Puzzle?
    var id: String { "\(category.rawValue)/\(tapped?.id ?? "")" }
}

struct PuzzleGridCard: View {
    let item: PuzzleEntry
    var isLocked = false

    var body: some View {
        VStack(alignment: .leading, spacing: PZSpacing.s) {
            PuzzleArtView(source: item.puzzle.image, pixelSize: 400)
                .aspectRatio(1.05, contentMode: .fit)
                .overlay(alignment: .topLeading) { newBadge }
                .overlay(alignment: .topTrailing) { statusBadge }
                .overlay(alignment: .topTrailing) { lockBadge }
                .clipShape(RoundedRectangle(cornerRadius: PZRadius.l, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.puzzle.title)
                    .font(PZFont.callout.weight(.bold))
                    .foregroundStyle(PZColor.ink)
                    .lineLimit(1)
                Text(meta)
                    .font(PZFont.caption)
                    .foregroundStyle(PZColor.muted)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var meta: String {
        let range = item.puzzle.pieceRange
        return "\(item.puzzle.category.title) · \(L10n.Library.pieceRange(range.lowerBound, range.upperBound))"
    }

    @ViewBuilder
    private var newBadge: some View {
        if item.puzzle.isNew, item.status == .notStarted {
            Text(L10n.Library.badgeNew.uppercased())
                .font(PZFont.eyebrow)
                .foregroundStyle(Color(hex: 0x18201D))
                .padding(.horizontal, 10)
                .frame(minHeight: 24)
                .background(PZColor.amber, in: Capsule())
                .padding(10)
        }
    }

    @ViewBuilder
    private var lockBadge: some View {
        if isLocked {
            Image(systemName: "lock.fill")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(PZColor.onFelt)
                .frame(width: 28, height: 28)
                .background(PZColor.felt, in: Circle())
                .padding(10)
                .accessibilityLabel(L10n.Pack.locked)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch item.status {
        case .completed:
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(PZColor.felt)
                .frame(width: 28, height: 28)
                .background(.white, in: Circle())
                .padding(10)
                .accessibilityLabel(L10n.Status.completed)
        case let .inProgress(fraction):
            Text(fraction, format: .percent.precision(.fractionLength(0)))
                .font(PZFont.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(PZColor.ink)
                .padding(.horizontal, 8)
                .frame(minHeight: 24)
                .background(.white, in: Capsule())
                .padding(10)
                .accessibilityLabel(L10n.Status.inProgress)
        case .notStarted:
            EmptyView()
        }
    }
}

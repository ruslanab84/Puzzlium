import PuzzliumDesignSystem
import PhotosUI
import PuzzliumDomain
import SwiftUI

struct LibraryView: View {
    @State private var viewModel: LibraryViewModel
    @Environment(AppRouter.self) private var router
    @State private var showsGallery = false
    @State private var showsCamera = false
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
        .alert(L10n.Library.photoFailed, isPresented: $photoFailed) {}
    }

    private var addPhotoMenu: some View {
        Menu {
            Button(L10n.Library.fromGallery, systemImage: "photo.on.rectangle") { showsGallery = true }
            if CameraPicker.isAvailable {
                Button(L10n.Library.takePhoto, systemImage: "camera") { showsCamera = true }
            }
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
                PZChip(L10n.Library.all, isSelected: viewModel.filter == .all) {
                    viewModel.filter = .all
                }
                ForEach(viewModel.categories, id: \.self) { category in
                    PZChip(category.title, isSelected: viewModel.filter == .category(category)) {
                        viewModel.filter = .category(category)
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
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
            LazyVGrid(columns: columns, spacing: PZSpacing.l) {
                ForEach(viewModel.visibleItems) { item in
                    Button { router.openSetup(for: item.puzzle) } label: {
                        PuzzleGridCard(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct PuzzleGridCard: View {
    let item: PuzzleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: PZSpacing.s) {
            PuzzleArtView(source: item.puzzle.image, pixelSize: 400)
                .aspectRatio(1.05, contentMode: .fit)
                .overlay(alignment: .topLeading) { newBadge }
                .overlay(alignment: .topTrailing) { statusBadge }
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

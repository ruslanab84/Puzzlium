import PuzzliumDesignSystem
import PuzzliumDomain
import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @Environment(AppRouter.self) private var router
    private let dependencies: FeatureDependencies

    init(dependencies: FeatureDependencies) {
        self.dependencies = dependencies
        _viewModel = State(initialValue: HomeViewModel(dependencies: dependencies))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PZSpacing.xl) {
                HomeHeader(date: viewModel.today, streak: viewModel.feed?.streak ?? 0)
                content
            }
            .padding(.horizontal, PZSpacing.xl)
            .padding(.top, PZSpacing.s)
            .padding(.bottom, PZSpacing.xxl)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(PZColor.ground)
        .toolbar(.hidden, for: .navigationBar)
        .task(id: router.contentVersion) { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 320)
        case .failed:
            ErrorStateView(message: L10n.Common.loadFailed) {
                Task { await viewModel.load() }
            }
        case let .loaded(feed):
            if let daily = feed.daily {
                DailyPuzzleCard(puzzle: daily, progress: feed.dailyProgress) {
                    router.openSetup(for: daily)
                }
            }
            if let event = viewModel.event {
                NavigationLink {
                    EventView(event: event, dependencies: dependencies)
                } label: {
                    EventCard(event: event, progress: viewModel.eventProgress)
                }
                .buttonStyle(.plain)
            }
            ContinueSection(items: feed.continueItems) { item in
                router.openSetup(for: item.puzzle)
            } onSeeAll: {
                router.selectedTab = .myPuzzles
            }
            if !feed.newArrivals.isEmpty {
                NewArrivalsRow(puzzles: feed.newArrivals) { puzzle in
                    router.openSetup(for: puzzle)
                }
            }
        }
    }
}

private struct HomeHeader: View {
    let date: Date
    let streak: Int

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(date, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(PZFont.footnote)
                    .foregroundStyle(PZColor.muted)
                Text(verbatim: "Puzzlium")
                    .font(PZFont.largeTitle)
                    .foregroundStyle(PZColor.ink)
                    .accessibilityAddTraits(.isHeader)
            }
            Spacer(minLength: PZSpacing.m)
            if streak > 0 {
                Label(L10n.Home.streak(streak), systemImage: "flame.fill")
                    .font(PZFont.footnote.weight(.bold))
                    .foregroundStyle(PZColor.ink)
                    .labelStyle(StreakLabelStyle())
                    .padding(.horizontal, PZSpacing.m)
                    .frame(minHeight: 36)
                    .background(PZColor.surface, in: Capsule())
            }
        }
    }
}

private struct StreakLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.foregroundStyle(PZColor.ember)
            configuration.title
        }
    }
}

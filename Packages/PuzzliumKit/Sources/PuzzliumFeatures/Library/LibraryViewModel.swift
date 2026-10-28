import Foundation
import Observation
import PuzzliumCore
import PuzzliumDomain

@Observable
@MainActor
final class LibraryViewModel {
    enum Filter: Hashable {
        case all
        case category(PuzzleCategory)
    }

    private(set) var items: [PuzzleEntry] = []
    private(set) var isLoading = true
    private(set) var loadFailed = false
    var filter: Filter = .all
    var query = ""

    private let useCase: GetLibraryUseCase
    private let puzzles: any PuzzleRepository

    init(dependencies: FeatureDependencies) {
        useCase = GetLibraryUseCase(puzzles: dependencies.puzzles, progress: dependencies.progress)
        puzzles = dependencies.puzzles
    }

    var categories: [PuzzleCategory] {
        let present = Set(items.map(\.puzzle.category))
        return PuzzleCategory.allCases.filter(present.contains)
    }

    var visibleItems: [PuzzleEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return items.filter { item in
            let matchesFilter = switch filter {
            case .all: true
            case let .category(category): item.puzzle.category == category
            }
            return matchesFilter && (trimmed.isEmpty || item.puzzle.title.localizedStandardContains(trimmed))
        }
    }

    var inProgress: [PuzzleEntry] {
        items
            .filter { if case .inProgress = $0.status { true } else { false } }
            .sorted { ($0.progress?.updatedAt ?? .distantPast) > ($1.progress?.updatedAt ?? .distantPast) }
    }

    var completed: [PuzzleEntry] {
        items
            .filter { $0.progress?.completedAt != nil }
            .sorted { ($0.progress?.completedAt ?? .distantPast) > ($1.progress?.completedAt ?? .distantPast) }
    }

    func load() async {
        do {
            items = try await useCase.execute()
            loadFailed = false
        } catch {
            Log.ui.error("Library failed: \(String(describing: error), privacy: .public)")
            loadFailed = items.isEmpty
        }
        isLoading = false
    }

    /// Turns a picked or captured picture into a puzzle and shows it. `false` when it isn't a usable image.
    func addPhoto(_ data: Data?) async -> Bool {
        guard let data else { return false }
        do {
            _ = try await puzzles.addPhoto(data)
        } catch {
            Log.ui.error("Adding photo failed: \(String(describing: error), privacy: .public)")
            return false
        }
        query = ""
        filter = .category(.photos)
        await load()
        return true
    }
}

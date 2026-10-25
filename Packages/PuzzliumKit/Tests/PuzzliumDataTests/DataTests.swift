import Foundation
import Testing
@testable import PuzzliumData
import PuzzliumDomain

@Suite("PuzzleDTO")
struct PuzzleDTOTests {
    private func dto(category: String = "nature", url: String = "https://cdn.example.com/a.jpg") -> PuzzleDTO {
        PuzzleDTO(
            id: "r1",
            title: ["en": "Quiet Lake", "ru": "Тихое озеро"],
            category: category,
            imageUrl: URL(string: url)!,
            pieceCounts: [36, 64, 999],
            isNew: nil
        )
    }

    @Test func picksPreferredLanguage() throws {
        let puzzle = try #require(dto().toDomain(preferredLanguages: ["ru-AZ", "en"]))
        #expect(puzzle.title == "Тихое озеро")
        #expect(puzzle.pieceCounts == [.p36, .p64])
        #expect(puzzle.isNew == false)
    }

    @Test func fallsBackToEnglish() throws {
        let puzzle = try #require(dto().toDomain(preferredLanguages: ["de"]))
        #expect(puzzle.title == "Quiet Lake")
    }

    @Test func rejectsInsecureOrUnknown() {
        #expect(dto(url: "http://cdn.example.com/a.jpg").toDomain() == nil)
        #expect(dto(category: "unknown").toDomain() == nil)
    }
}

@Suite("SwiftDataProgressStore")
struct ProgressStoreTests {
    private func sample(_ placed: Int, completed: Bool = false, completedAt: Date? = nil) -> PuzzleProgress {
        PuzzleProgress(
            puzzleID: "p1",
            pieceCount: .p36,
            placedCount: placed,
            rotationEnabled: false,
            elapsed: 10,
            isCompleted: completed,
            updatedAt: .now,
            completedAt: completedAt,
            snapshot: Data([1, 2, 3])
        )
    }

    @Test func upsertKeepsLastCompletionDate() async throws {
        let store = SwiftDataProgressStore(modelContainer: try PersistenceFactory.makeContainer(inMemory: true))
        let finished = Date(timeIntervalSince1970: 1_000)
        try await store.save(sample(36, completed: true, completedAt: finished))
        try await store.save(sample(3))

        let saved = try #require(try await store.progress(for: "p1"))
        #expect(saved.placedCount == 3)
        #expect(saved.completedAt == finished)
        #expect(try await store.allProgress().count == 1)
    }

    @Test func recordsCompletions() async throws {
        let store = SwiftDataProgressStore(modelContainer: try PersistenceFactory.makeContainer(inMemory: true))
        try await store.recordCompletion(PuzzleCompletion(puzzleID: "p1", pieceCount: .p36, duration: 60, date: .now))
        #expect(try await store.completionDates().count == 1)
    }
}

@Suite("Bundled content")
struct BundledContentTests {
    @Test func catalogIsValid() {
        let puzzles = BundledCatalog.puzzles
        #expect(puzzles.count == 22)
        #expect(Set(puzzles.map(\.id)).count == puzzles.count)
        #expect(puzzles.allSatisfy { !$0.title.isEmpty })
    }

    @Test(arguments: ArtStyle.allCases)
    func artRenders(style: ArtStyle) {
        let image = ProceduralArtRenderer.render(style: style, variant: 1, pixelSize: 128)
        #expect(image?.width == 128)
    }

    @Test(arguments: BundledCatalog.puzzles.filter { $0.category == .landmarks })
    func landmarkPhotoLoads(puzzle: Puzzle) async throws {
        let loader = PuzzleImageLoader(cacheDirectory: URL.temporaryDirectory.appending(path: UUID().uuidString))
        let image = try await loader.image(for: puzzle.image, pixelSize: 256)
        #expect(image.cgImage.width == 256)
    }

    @Test func offlineRepositoryServesBundledCatalog() async throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let repository = DefaultPuzzleRepository(client: nil, cacheDirectory: directory)
        #expect(try await repository.catalog().count == 22)
    }
}

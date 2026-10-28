import Foundation
import PuzzliumCore
import PuzzliumDomain

/// Offline-first catalog: memory → disk cache → bundled. A stale cache refreshes in the background,
/// so the UI never waits on the network.
public actor DefaultPuzzleRepository: PuzzleRepository {
    private let client: (any HTTPClient)?
    private let cacheURL: URL
    private let photosDirectory: URL
    private let maxAge: TimeInterval
    private var memory: [Puzzle]?
    private var refreshTask: Task<Void, Never>?

    public init(
        client: (any HTTPClient)?,
        cacheDirectory: URL = URL.cachesDirectory,
        photosDirectory: URL = UserPhotos.directory,
        maxAge: TimeInterval = 12 * 3600
    ) {
        self.client = client
        self.cacheURL = cacheDirectory.appending(path: "catalog-v1.json")
        self.photosDirectory = photosDirectory
        self.maxAge = maxAge
    }

    public func catalog() async throws -> [Puzzle] {
        if let memory {
            scheduleRefreshIfNeeded()
            return photoPuzzles() + memory
        }
        let local = combined(with: loadDiskCache() ?? [])
        memory = local
        scheduleRefreshIfNeeded()
        return photoPuzzles() + local
    }

    // MARK: - Player photos

    public func addPhoto(_ imageData: Data) throws -> Puzzle {
        guard let image = ImageDownsampler.squareImage(from: imageData, pixelSize: UserPhotos.pixelSize),
              let jpeg = ImageDownsampler.jpegData(from: image)
        else { throw ImageLoadingError.decodingFailed }
        try FileManager.default.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
        let name = "\(UUID().uuidString).jpg"
        try jpeg.write(to: photosDirectory.appending(path: name), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        return UserPhotos.puzzle(name: name, addedAt: Date())
    }

    /// Newest first, so a fresh photo leads the library.
    private func photoPuzzles() -> [Puzzle] {
        let files = (try? FileManager.default.contentsOfDirectory(at: photosDirectory, includingPropertiesForKeys: [.creationDateKey])) ?? []
        return files
            .map { ($0.lastPathComponent, (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast) }
            .sorted { $0.1 > $1.1 }
            .map { UserPhotos.puzzle(name: $0.0, addedAt: $0.1) }
    }

    private func combined(with puzzles: [Puzzle]) -> [Puzzle] {
        let ids = Set(puzzles.map(\.id))
        return puzzles + BundledCatalog.puzzles.filter { !ids.contains($0.id) }
    }

    // MARK: - Refresh

    private var isCacheStale: Bool {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: cacheURL.path()),
              let modified = attributes[.modificationDate] as? Date
        else { return true }
        return Date().timeIntervalSince(modified) > maxAge
    }

    private func scheduleRefreshIfNeeded() {
        guard let client, refreshTask == nil, isCacheStale else { return }
        refreshTask = Task {
            await refresh(using: client)
        }
    }

    private func refresh(using client: any HTTPClient) async {
        defer { refreshTask = nil }
        do {
            let response = try await client.send(CatalogEndpoints.catalog())
            let puzzles = response.puzzles.compactMap { $0.toDomain() }
            guard !puzzles.isEmpty else { return }
            memory = combined(with: puzzles)
            try saveDiskCache(puzzles)
        } catch {
            Log.data.error("Catalog refresh failed: \(String(describing: error), privacy: .public)")
        }
    }

    // MARK: - Disk cache

    private func loadDiskCache() -> [Puzzle]? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        return try? JSONDecoder().decode([Puzzle].self, from: data)
    }

    private func saveDiskCache(_ puzzles: [Puzzle]) throws {
        let data = try JSONEncoder().encode(puzzles)
        try data.write(to: cacheURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}

/// Where player photos live. Application Support, not Caches: the system must never purge them.
public enum UserPhotos {
    public static let directory = URL.applicationSupportDirectory.appending(path: "photos")
    /// Stored square, already big enough for the largest board.
    static let pixelSize = 2048

    static func puzzle(name: String, addedAt date: Date) -> Puzzle {
        Puzzle(
            id: "photo-\(name)",
            title: date.formatted(date: .abbreviated, time: .shortened),
            category: .photos,
            image: .photo(name)
        )
    }
}

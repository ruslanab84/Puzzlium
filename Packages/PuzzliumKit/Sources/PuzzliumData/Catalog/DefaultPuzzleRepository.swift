import Foundation
import PuzzliumCore
import PuzzliumDomain

/// Offline-first catalog: memory → disk cache → bundled. A stale cache refreshes in the background,
/// so the UI never waits on the network.
public actor DefaultPuzzleRepository: PuzzleRepository {
    private let client: (any HTTPClient)?
    private let cacheURL: URL
    private let maxAge: TimeInterval
    private var memory: [Puzzle]?
    private var refreshTask: Task<Void, Never>?

    public init(
        client: (any HTTPClient)?,
        cacheDirectory: URL = URL.cachesDirectory,
        maxAge: TimeInterval = 12 * 3600
    ) {
        self.client = client
        self.cacheURL = cacheDirectory.appending(path: "catalog-v1.json")
        self.maxAge = maxAge
    }

    public func catalog() async throws -> [Puzzle] {
        if let memory {
            scheduleRefreshIfNeeded()
            return memory
        }
        let local = loadDiskCache() ?? BundledCatalog.puzzles
        memory = local
        scheduleRefreshIfNeeded()
        return local
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
            memory = puzzles
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

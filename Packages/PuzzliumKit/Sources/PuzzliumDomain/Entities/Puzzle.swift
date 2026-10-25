import Foundation

public struct Puzzle: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let title: String
    public let category: PuzzleCategory
    public let image: PuzzleImageSource
    public let pieceCounts: [PieceCount]
    public let isNew: Bool

    public init(
        id: String,
        title: String,
        category: PuzzleCategory,
        image: PuzzleImageSource,
        pieceCounts: [PieceCount] = PieceCount.allCases,
        isNew: Bool = false
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.image = image
        self.pieceCounts = pieceCounts.isEmpty ? PieceCount.allCases : pieceCounts.sorted()
        self.isNew = isNew
    }

    /// Default difficulty offered first in setup.
    public var recommendedPieceCount: PieceCount {
        pieceCounts.contains(.p64) ? .p64 : (pieceCounts.first ?? .p64)
    }

    public var pieceRange: ClosedRange<Int> {
        (pieceCounts.first?.rawValue ?? 36)...(pieceCounts.last?.rawValue ?? 400)
    }
}

public enum PuzzleCategory: String, CaseIterable, Codable, Sendable {
    case nature
    case cities
    case art
}

/// Built-in illustration styles rendered on device (no download needed).
public enum ArtStyle: String, CaseIterable, Codable, Sendable {
    case dunes
    case lake
    case city
    case bloom
}

public enum PuzzleImageSource: Hashable, Codable, Sendable {
    case procedural(style: ArtStyle, variant: Int)
    case remote(URL)

    /// Stable key for caches.
    public var cacheKey: String {
        switch self {
        case let .procedural(style, variant): "art-\(style.rawValue)-\(variant)"
        case let .remote(url): url.absoluteString
        }
    }
}

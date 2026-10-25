import Foundation
import PuzzliumDomain

/// Wire format of `GET /v1/catalog`.
struct CatalogResponseDTO: Decodable, Sendable {
    let puzzles: [PuzzleDTO]
}

struct PuzzleDTO: Decodable, Sendable {
    let id: String
    /// Language code → title, e.g. ["en": "Quiet Lake", "ru": "Тихое озеро"].
    let title: [String: String]
    let category: String
    let imageUrl: URL
    let pieceCounts: [Int]?
    let isNew: Bool?

    func toDomain(preferredLanguages: [String] = Locale.preferredLanguages) -> Puzzle? {
        guard let category = PuzzleCategory(rawValue: category),
              imageUrl.scheme == "https",
              let resolvedTitle = localizedTitle(preferredLanguages)
        else { return nil }

        return Puzzle(
            id: id,
            title: resolvedTitle,
            category: category,
            image: .remote(imageUrl),
            pieceCounts: (pieceCounts ?? []).compactMap(PieceCount.init(rawValue:)),
            isNew: isNew ?? false
        )
    }

    private func localizedTitle(_ languages: [String]) -> String? {
        for language in languages {
            let code = String(language.prefix(2))
            if let value = title[code] { return value }
        }
        return title["en"] ?? title.values.first
    }
}

enum CatalogEndpoints {
    static func catalog() -> Endpoint<CatalogResponseDTO> {
        Endpoint(path: "v1/catalog")
    }
}

import Foundation
import PuzzliumDomain

/// The event that ships with the app: three chapters of three levels, 36 → 225 pieces.
public enum BundledEvent {
    public static var autumn: PuzzleEvent {
        let gallery = Dictionary(BundledCatalog.puzzles.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        // Level ids predate the gallery pictures; keep them so saved progress survives.
        func level(_ slug: String, _ image: String, _ pieces: PieceCount) -> EventLevel {
            let source = gallery[image]
            return EventLevel(
                puzzle: Puzzle(
                    id: "e-autumn-\(slug)",
                    title: source?.title ?? image,
                    category: source?.category ?? .art,
                    image: .bundled(image),
                    pieceCounts: [pieces]
                ),
                pieceCount: pieces
            )
        }

        return PuzzleEvent(
            id: "autumn-trail",
            title: CatalogStrings.autumnTitle,
            chapters: [
                EventChapter(
                    id: "autumn-1",
                    postcardTitle: CatalogStrings.goldenWoods,
                    postcard: .bundled("post-impressionist-02"),
                    levels: [
                        level("amber-dunes", "illustration-02", .p36),
                        level("misty-lake", "animal-02", .p36),
                        level("harvest-garden", "illustration-14", .p64)
                    ]
                ),
                EventChapter(
                    id: "autumn-2",
                    postcardTitle: CatalogStrings.lanternTown,
                    postcard: .bundled("art-06"),
                    levels: [
                        level("lantern-street", "art-09", .p64),
                        level("copper-hills", "city-05", .p100),
                        level("twilight-pond", "post-impressionist-04", .p100)
                    ]
                ),
                EventChapter(
                    id: "autumn-3",
                    postcardTitle: CatalogStrings.firstFrost,
                    postcard: .bundled("art-13"),
                    levels: [
                        level("rowan-bloom", "post-impressionist-08", .p144),
                        level("rainy-square", "art-20", .p144),
                        level("frost-lake", "illustration-15", .p225)
                    ]
                )
            ]
        )
    }
}

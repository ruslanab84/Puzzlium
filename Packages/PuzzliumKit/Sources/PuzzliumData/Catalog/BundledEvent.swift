import Foundation
import PuzzliumDomain

/// The event that ships with the app: three chapters of three levels, 36 → 225 pieces.
public enum BundledEvent {
    public static var autumn: PuzzleEvent {
        PuzzleEvent(
            id: "autumn-trail",
            title: CatalogStrings.autumnTitle,
            chapters: [
                EventChapter(
                    id: "autumn-1",
                    postcardTitle: CatalogStrings.goldenWoods,
                    postcard: .procedural(style: .dunes, variant: 5),
                    levels: [
                        level("amber-dunes", CatalogStrings.amberDunes, .dunes, 3, .p36),
                        level("misty-lake", CatalogStrings.mistyLake, .lake, 3, .p36),
                        level("harvest-garden", CatalogStrings.harvestGarden, .bloom, 3, .p64)
                    ]
                ),
                EventChapter(
                    id: "autumn-2",
                    postcardTitle: CatalogStrings.lanternTown,
                    postcard: .procedural(style: .city, variant: 5),
                    levels: [
                        level("lantern-street", CatalogStrings.lanternStreet, .city, 3, .p64),
                        level("copper-hills", CatalogStrings.copperHills, .dunes, 4, .p100),
                        level("twilight-pond", CatalogStrings.twilightPond, .lake, 4, .p100)
                    ]
                ),
                EventChapter(
                    id: "autumn-3",
                    postcardTitle: CatalogStrings.firstFrost,
                    postcard: .procedural(style: .bloom, variant: 5),
                    levels: [
                        level("rowan-bloom", CatalogStrings.rowanBloom, .bloom, 4, .p144),
                        level("rainy-square", CatalogStrings.rainySquare, .city, 4, .p144),
                        level("frost-lake", CatalogStrings.frostLake, .lake, 5, .p225)
                    ]
                )
            ]
        )
    }

    private static func level(_ slug: String, _ title: String, _ style: ArtStyle, _ variant: Int, _ pieces: PieceCount) -> EventLevel {
        EventLevel(
            puzzle: Puzzle(
                id: "e-autumn-\(slug)",
                title: title,
                category: style == .city ? .cities : (style == .bloom ? .art : .nature),
                image: .procedural(style: style, variant: variant),
                pieceCounts: [pieces]
            ),
            pieceCount: pieces
        )
    }
}

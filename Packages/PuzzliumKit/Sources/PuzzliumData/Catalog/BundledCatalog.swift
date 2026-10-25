import Foundation
import PuzzliumDomain

/// Ships with the app so the first launch (and airplane mode) always has puzzles.
enum BundledCatalog {
    static var puzzles: [Puzzle] {
        [
            Puzzle(id: "b-desert-glow", title: CatalogStrings.desertGlow, category: .nature, image: .procedural(style: .dunes, variant: 0)),
            Puzzle(id: "b-quiet-lake", title: CatalogStrings.quietLake, category: .nature, image: .procedural(style: .lake, variant: 0), isNew: true),
            Puzzle(id: "b-night-skyline", title: CatalogStrings.nightSkyline, category: .cities, image: .procedural(style: .city, variant: 0), isNew: true),
            Puzzle(id: "b-spring-bloom", title: CatalogStrings.springBloom, category: .art, image: .procedural(style: .bloom, variant: 0)),
            Puzzle(id: "b-violet-dunes", title: CatalogStrings.violetDunes, category: .nature, image: .procedural(style: .dunes, variant: 1)),
            Puzzle(id: "b-moonlit-fjord", title: CatalogStrings.moonlitFjord, category: .nature, image: .procedural(style: .lake, variant: 1), isNew: true),
            Puzzle(id: "b-sunset-avenue", title: CatalogStrings.sunsetAvenue, category: .cities, image: .procedural(style: .city, variant: 1)),
            Puzzle(id: "b-blue-garden", title: CatalogStrings.blueGarden, category: .art, image: .procedural(style: .bloom, variant: 1)),
            Puzzle(id: "b-morning-sands", title: CatalogStrings.morningSands, category: .nature, image: .procedural(style: .dunes, variant: 2)),
            Puzzle(id: "b-autumn-valley", title: CatalogStrings.autumnValley, category: .nature, image: .procedural(style: .lake, variant: 2)),
            Puzzle(id: "b-harbor-noon", title: CatalogStrings.harborNoon, category: .cities, image: .procedural(style: .city, variant: 2)),
            Puzzle(id: "b-marigold", title: CatalogStrings.marigold, category: .art, image: .procedural(style: .bloom, variant: 2))
        ]
    }
}

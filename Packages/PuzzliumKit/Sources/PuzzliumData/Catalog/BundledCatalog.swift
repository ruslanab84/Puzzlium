import Foundation
import PuzzliumDomain

/// Ships with the app so the first launch (and airplane mode) always has puzzles.
enum BundledCatalog {
    static var puzzles: [Puzzle] {
        [
            photo("nature-northern-lights", CatalogStrings.northernLights, .nature, isNew: true),
            photo("nature-autumn-forest", CatalogStrings.autumnForest, .nature, isNew: true),
            photo("nature-tropical-beach", CatalogStrings.tropicalBeach, .nature),
            photo("nature-sahara-night", CatalogStrings.saharaNight, .nature),
            photo("nature-icelandic-waterfall", CatalogStrings.icelandicWaterfall, .nature),
            photo("nature-forest-falls", CatalogStrings.forestFalls, .nature),
            photo("nature-mount-fuji", CatalogStrings.mountFuji, .nature),
            photo("nature-glacier-lagoon", CatalogStrings.glacierLagoon, .nature),
            photo("nature-himalayan-lake", CatalogStrings.himalayanLake, .nature),
            photo("nature-tulip-fields", CatalogStrings.tulipFields, .nature),
            photo("city-amsterdam", CatalogStrings.amsterdam, .cities, isNew: true),
            photo("city-frankfurt", CatalogStrings.frankfurt, .cities),
            photo("city-hong-kong", CatalogStrings.hongKong, .cities),
            photo("city-new-york", CatalogStrings.newYork, .cities),
            photo("city-prague", CatalogStrings.prague, .cities),
            photo("city-rio", CatalogStrings.rio, .cities),
            photo("city-santorini", CatalogStrings.santorini, .cities),
            photo("city-singapore", CatalogStrings.singapore, .cities),
            photo("city-tokyo", CatalogStrings.tokyo, .cities, isNew: true),
            photo("city-venice", CatalogStrings.venice, .cities),
            photo("art-starry-night", CatalogStrings.starryNight, .art, isNew: true),
            photo("art-great-wave", CatalogStrings.greatWave, .art, isNew: true),
            photo("art-water-lilies", CatalogStrings.waterLilies, .art),
            photo("art-the-kiss", CatalogStrings.theKiss, .art),
            photo("art-pearl-earring", CatalogStrings.pearlEarring, .art),
            photo("art-grande-jatte", CatalogStrings.grandeJatte, .art),
            photo("art-hunters-snow", CatalogStrings.huntersSnow, .art),
            photo("art-sunflowers", CatalogStrings.sunflowers, .art),
            photo("art-moulin-galette", CatalogStrings.moulinGalette, .art),
            photo("art-almond-blossom", CatalogStrings.almondBlossom, .art),
            photo("landmark-eiffel-tower", CatalogStrings.eiffelTower, .landmarks, isNew: true),
            photo("landmark-colosseum", CatalogStrings.colosseum, .landmarks, isNew: true),
            photo("landmark-great-wall", CatalogStrings.greatWall, .landmarks, isNew: true),
            photo("landmark-taj-mahal", CatalogStrings.tajMahal, .landmarks),
            photo("landmark-giza-pyramids", CatalogStrings.gizaPyramids, .landmarks),
            photo("landmark-statue-of-liberty", CatalogStrings.statueOfLiberty, .landmarks),
            photo("landmark-machu-picchu", CatalogStrings.machuPicchu, .landmarks),
            photo("landmark-sydney-opera-house", CatalogStrings.sydneyOperaHouse, .landmarks),
            photo("landmark-big-ben", CatalogStrings.bigBen, .landmarks),
            photo("landmark-saint-basils", CatalogStrings.saintBasils, .landmarks)
        ]
    }

    /// Photo puzzles; the JPEG is `Resources/<name>.jpg` (credits in README).
    private static func photo(_ name: String, _ title: String, _ category: PuzzleCategory, isNew: Bool = false) -> Puzzle {
        Puzzle(id: "b-\(name)", title: title, category: category, image: .bundled(name), isNew: isNew)
    }
}

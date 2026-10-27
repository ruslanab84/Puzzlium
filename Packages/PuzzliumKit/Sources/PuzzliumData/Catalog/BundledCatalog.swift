import Foundation
import PuzzliumDomain

/// Ships with the app so the first launch (and airplane mode) always has puzzles.
enum BundledCatalog {
    static var puzzles: [Puzzle] {
        [
            photo("landmark-statue-of-liberty", CatalogStrings.statueOfLiberty, .landmarks, isNew: true),
            photo("country-france", CatalogStrings.france, .countries),
            photo("country-italy", CatalogStrings.italy, .countries),
            photo("country-uk", CatalogStrings.uk, .countries),
            photo("country-egypt", CatalogStrings.egypt, .countries),
            photo("country-japan", CatalogStrings.japan, .countries),
            photo("country-china", CatalogStrings.china, .countries),
            photo("country-india", CatalogStrings.india, .countries),
            photo("country-russia", CatalogStrings.russia, .countries),
            photo("country-netherlands", CatalogStrings.netherlands, .countries),
            photo("country-greece", CatalogStrings.greece, .countries),
            photo("country-brazil", CatalogStrings.brazil, .countries),
            photo("country-australia", CatalogStrings.australia, .countries),
            photo("country-mexico", CatalogStrings.mexico, .countries),
            photo("country-peru", CatalogStrings.peru, .countries),
            photo("country-canada", CatalogStrings.canada, .countries),
            photo("country-kenya", CatalogStrings.kenya, .countries),
            photo("country-turkey", CatalogStrings.turkey, .countries),
            photo("country-switzerland", CatalogStrings.switzerland, .countries),
            photo("country-spain", CatalogStrings.spain, .countries),
            photo("country-thailand", CatalogStrings.thailand, .countries)
        ]
    }

    /// Photo puzzles; the JPEG is `Resources/<name>.jpg` (drawn for Puzzlium).
    private static func photo(_ name: String, _ title: String, _ category: PuzzleCategory, isNew: Bool = false) -> Puzzle {
        Puzzle(id: "b-\(name)", title: title, category: category, image: .bundled(name), isNew: isNew)
    }
}

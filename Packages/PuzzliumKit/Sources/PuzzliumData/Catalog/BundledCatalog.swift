import Foundation
import PuzzliumDomain

enum BundledCatalog {
    static var puzzles: [Puzzle] {
        let titles = [
            "London",
            "Paris",
            "New York",
            "Venice",
            "Prague",
            "Barcelona",
            "Istanbul",
            "Kyoto",
            "Mount Fuji",
            "Amsterdam",
            "Lisbon",
            "Vienna",
            "Budapest",
            "Athens",
            "Sydney",
            "San Francisco",
            "Rio de Janeiro",
            "Cairo",
            "Marrakech",
            "Dubrovnik",
        ]
        return titles.enumerated().map { index, title in
            let number = index + 1
            let name = String(format: "city-%02d", number)
            return Puzzle(id: name, title: title, category: .cities, image: .bundled(name))
        }
    }
}

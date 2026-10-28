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
        let cities = titles.enumerated().map { index, title in
            let number = index + 1
            let name = String(format: "city-%02d", number)
            return Puzzle(id: name, title: title, category: .cities, image: .bundled(name))
        }
        let animals = [
            "Hare", "Squirrel", "Red Panda", "Deer", "Fox", "Hedgehog", "Owl",
            "Kitten", "Puppy", "Horse", "Panda", "Raccoon", "Koala", "Otter",
            "Penguin", "Bear Cub", "Tiger Cub", "Swan", "Elephant Calf", "Dolphin"
        ].enumerated().map { index, title in
            let name = String(format: "animal-%02d", index + 1)
            return Puzzle(id: name, title: title, category: .nature, image: .bundled(name))
        }
        let art = [
            "Golden Harbor", "Rainy Paris", "Japanese Garden", "Sunflowers", "Alpine Village",
            "Venice at Twilight", "Wild Horses", "Cappadocia Sunrise", "Cozy Bookshop", "Stormy Lighthouse",
            "Lavender Fields", "Tropical Parrots", "Northern Lights", "Colorful Market", "Palace Peacock",
            "Mountain Train", "Coral Reef", "Desert Caravan", "Ballet Studio", "Castle in the Mist"
        ].enumerated().map { index, title in
            let name = String(format: "art-%02d", index + 1)
            return Puzzle(id: name, title: title, category: .art, image: .bundled(name))
        }
        return cities + animals + art
    }
}

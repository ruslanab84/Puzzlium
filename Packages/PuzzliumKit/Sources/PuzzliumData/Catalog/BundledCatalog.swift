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
        let postImpressionism = [
            "Starry Riverside", "Golden Wheat Fields", "Sunflower Vase", "Paris in the Rain",
            "Almond Orchard", "Mediterranean Boats", "Sunny Bedroom", "Snowy Village",
            "Lavender Farm", "Market Day", "Mountain Viaduct", "Poppy Fields",
            "Quiet Library", "Tropical Parrots", "Stormy Lighthouse", "Venetian Sunset",
            "Olive Grove", "Desert Caravan", "Lily Pond", "Coastal Cliffs"
        ].enumerated().map { index, title in
            let name = String(format: "post-impressionist-%02d", index + 1)
            return Puzzle(id: name, title: title, category: .art, image: .bundled(name))
        }
        let flowers = [
            "Roses", "Sunflowers", "Cherry Blossoms", "Irises", "Lilies", "Tulips", "Lavender",
            "Peonies", "Poppies", "Hydrangeas", "Orchids", "Daisies", "Dahlias", "Lotus",
            "Daffodils", "Magnolia", "Pansies", "Hibiscus", "Zinnias", "Jasmine"
        ].enumerated().map { index, title in
            let name = String(format: "flower-%02d", index + 1)
            return Puzzle(id: name, title: title, category: .flowers, image: .bundled(name))
        }
        let kids = [
            "Dinosaur Adventure", "Toy Train", "Space Rocket", "Treasure Island", "Farm Friends",
            "Friendly Dragon", "Ocean Adventure", "Playful Penguins", "Balloon Ride", "Teddy Bear Picnic",
            "Robot City", "Jungle Treehouse", "Rainbow Unicorn", "Playful Puppies", "Fire Truck Friends",
            "Animal Bakery", "Ocean Whales", "Animal Circus", "Woodland Bicycle Ride", "Candy Village"
        ].enumerated().map { index, title in
            let name = String(format: "kids-%02d", index + 1)
            return Puzzle(id: name, title: title, category: .kids, image: .bundled(name))
        }
        return cities + animals + art + postImpressionism + flowers + kids
    }
}

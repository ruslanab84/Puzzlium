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
        let cute = [
            "Dinosaur Adventure", "Toy Train", "Space Rocket", "Treasure Island", "Farm Friends",
            "Friendly Dragon", "Ocean Adventure", "Playful Penguins", "Balloon Ride", "Teddy Bear Picnic",
            "Robot City", "Jungle Treehouse", "Rainbow Unicorn", "Playful Puppies", "Fire Truck Friends",
            "Animal Bakery", "Ocean Whales", "Animal Circus", "Woodland Bicycle Ride", "Candy Village"
        ].enumerated().map { index, title in
            let name = String(format: "kids-%02d", index + 1)
            return Puzzle(id: name, title: title, category: .cute, image: .bundled(name))
        }
        let space = [
            "Lunar Explorer", "Spiral Galaxy", "Saturn and Moons", "Mars Rover", "Stellar Nursery",
            "Orbital Sunrise", "Jupiter", "Passing Comet", "Twin Suns", "Space Telescope",
            "Rocket Launch", "Icy Moon", "Spacewalk", "Planetary Alignment", "Meteor Shower",
            "Aurora World", "Black Hole", "Lunar Base", "Asteroid Voyage", "Earthrise"
        ].enumerated().map { index, title in
            let name = String(format: "space-%02d", index + 1)
            return Puzzle(id: name, title: title, category: .space, image: .bundled(name))
        }
        let wildlife = [
            "Lion", "Giraffe", "Zebras", "Arctic Fox", "Wolf", "Brown Bear", "Sea Turtle",
            "Polar Bear", "Leopard", "Flamingos", "Gorilla", "Orangutan", "Eagle", "Dolphins",
            "Kangaroo", "Puffins", "Hippopotamus", "Meerkats", "Chameleon", "Snow Leopard"
        ].enumerated().map { index, title in
            let name = String(format: "wild-animal-%02d", index + 1)
            return Puzzle(id: name, title: title, category: .animals, image: .bundled(name))
        }
        let food = [
            "Fruit Basket", "Vegetable Harvest", "Margherita Pizza", "Summer Berries", "Sushi Platter",
            "Citrus Fruits", "Berry Pancakes", "Watermelon Picnic", "Tomato Pasta", "Peppers and Tomatoes",
            "Cafe Pastries", "Tropical Fruits", "Burger and Fries", "Fresh Salad", "Chocolate Cake",
            "Orchard Apples and Pears", "Vegetable Tacos", "Fruit Ice Cream", "Bread and Cheese", "Summer Orchard"
        ].enumerated().map { index, title in
            let name = String(format: "food-%02d", index + 1)
            return Puzzle(id: name, title: title, category: .food, image: .bundled(name))
        }
        let illustrations = [
            "Kingfisher", "Autumn Fox", "Squirrel", "Meadow Rabbit", "Night Owl", "Ocean Dolphin",
            "Lighthouse Sailboat", "Hot Air Balloons", "Window Cat", "Park Puppy", "Pond Frog",
            "Coral Turtle", "Flower Shop Bicycle", "Apple Orchard", "Lakeside Cottage", "Jungle Parrot",
            "Aurora Penguin", "Garden Ladybug", "Valley Train", "Whale and Sailboat"
        ].enumerated().map { index, title in
            let name = String(format: "illustration-%02d", index + 1)
            return Puzzle(id: name, title: title, category: .illustrations, image: .bundled(name))
        }
        let patterns = [
            ("ghosts", "Reading Ghosts"), ("cats", "Cozy Cats"), ("foxes", "Autumn Foxes"),
            ("rabbits", "Spring Rabbits"), ("bears", "Honey Bears"), ("owls", "Sleepy Owls"),
            ("hedgehogs", "Woodland Hedgehogs"), ("whales", "Whales and Sailboats"),
            ("dinosaurs", "Little Dinosaurs"), ("berries", "Summer Berries"), ("tea", "Tea Time"),
            ("village", "Little Village"), ("sunflowers", "Sunny Garden"), ("space", "Little Planets"),
            ("butterflies", "Butterfly Garden"), ("penguins", "Winter Penguins"), ("ducks", "Rainy Ducks"),
            ("autumn", "Autumn Ghosts"), ("dogs", "Playful Dogs"), ("woodland", "Woodland Snails")
        ].map { name, title in
            Puzzle(id: "pattern-\(name)", title: title, category: .patterns, image: .bundled(name))
        }
        let planets = [
            "Blue Planet", "Golden Rings", "Red Planet", "Purple Giant", "Icy Planet",
            "Green and Blue", "Orange Giant", "Volcanic World", "Lavender Rings", "Cobalt Sky",
            "Planetary Pair", "Golden Halo", "Pink World", "Emerald World", "Planetary System",
            "Pearl Rings", "Rust Planet", "Violet Rings", "Blue and Gold", "Colorful Planets"
        ].enumerated().map { index, title in
            let name = String(format: "planet-%02d", index + 1)
            return Puzzle(id: name, title: title, category: .planets, image: .bundled(name))
        }
        let underwater = [
            ("tropical-fish", "Tropical Fish"), ("shark", "Reef Shark"), ("dolphins", "Dolphins"),
            ("sea-turtles", "Sea Turtles"), ("shipwreck", "Sunken Ship"), ("octopus", "Octopus and Shipwreck"),
            ("manta-rays", "Manta Rays"), ("clownfish", "Clownfish"), ("jellyfish", "Jellyfish"),
            ("seahorses", "Seahorses"), ("whale", "Whale"), ("hammerheads", "Hammerhead Sharks"),
            ("treasure", "Sunken Treasure"), ("reef-fish", "Reef Fish"), ("whale-shark", "Whale Shark"),
            ("sea-lions", "Sea Lions"), ("crab-and-starfish", "Crab and Starfish"), ("squid", "Squid"),
            ("submarine", "Sunken Submarine"), ("coral-reef", "Coral Reef")
        ].map { name, title in
            let resource = "underwater-\(name)"
            return Puzzle(id: resource, title: title, category: .underwater, image: .bundled(resource))
        }
        return cities + animals + art + postImpressionism + flowers + cute + space + wildlife + food + illustrations + patterns + planets + underwater
    }
}

// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PuzzliumKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "PuzzliumCore", targets: ["PuzzliumCore"]),
        .library(name: "PuzzliumDomain", targets: ["PuzzliumDomain"]),
        .library(name: "PuzzliumData", targets: ["PuzzliumData"]),
        .library(name: "PuzzliumFeatures", targets: ["PuzzliumFeatures"])
    ],
    targets: [
        // Leaf utilities shared by every layer (logging, analytics contract).
        .target(name: "PuzzliumCore"),

        // Entities, repository protocols and use cases. No framework dependencies.
        .target(name: "PuzzliumDomain"),

        // Pure puzzle logic: layout, piece geometry, snapping, rendering.
        .target(name: "PuzzliumEngine"),

        // Offline-first implementations of Domain protocols.
        .target(
            name: "PuzzliumData",
            dependencies: ["PuzzliumDomain", "PuzzliumCore"],
            resources: [.process("Resources")]
        ),

        // Colors, typography and reusable SwiftUI components.
        .target(name: "PuzzliumDesignSystem"),

        // SwiftUI screens + @Observable view models.
        .target(
            name: "PuzzliumFeatures",
            dependencies: ["PuzzliumDomain", "PuzzliumEngine", "PuzzliumDesignSystem", "PuzzliumCore"],
            resources: [.process("Resources")]
        ),

        .testTarget(name: "PuzzliumDomainTests", dependencies: ["PuzzliumDomain"]),
        .testTarget(name: "PuzzliumEngineTests", dependencies: ["PuzzliumEngine"]),
        .testTarget(name: "PuzzliumDataTests", dependencies: ["PuzzliumData", "PuzzliumDomain"])
    ],
    swiftLanguageModes: [.v6]
)

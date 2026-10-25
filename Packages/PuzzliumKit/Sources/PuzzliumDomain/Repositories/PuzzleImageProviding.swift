#if canImport(CoreGraphics)
import CoreGraphics

/// Immutable decoded image. `CGImage` is thread-safe once created.
public struct PuzzleImage: @unchecked Sendable {
    public let cgImage: CGImage

    public init(cgImage: CGImage) {
        self.cgImage = cgImage
    }
}

public protocol PuzzleImageProviding: Sendable {
    /// Square image, `pixelSize` × `pixelSize`, center-cropped.
    func image(for source: PuzzleImageSource, pixelSize: Int) async throws -> PuzzleImage
}
#endif

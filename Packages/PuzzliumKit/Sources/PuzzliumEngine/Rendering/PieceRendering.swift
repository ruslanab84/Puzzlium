#if canImport(CoreGraphics)
import CoreGraphics

extension PieceGeometry {
    public func path(for index: Int, transform: CGAffineTransform = .identity) -> CGPath {
        let path = CGMutablePath()
        for element in outline(for: index) {
            switch element {
            case let .move(point):
                path.move(to: point, transform: transform)
            case let .line(point):
                path.addLine(to: point, transform: transform)
            case let .curve(end, control1, control2):
                path.addCurve(to: end, control1: control1, control2: control2, transform: transform)
            case .close:
                path.closeSubpath()
            }
        }
        return path
    }

    /// Every piece outline in one path: drawn once as the empty-slot grid.
    public func slotsPath() -> CGPath {
        let path = CGMutablePath()
        for index in 0..<layout.grid.count {
            path.addPath(self.path(for: index))
        }
        return path
    }
}

/// Pre-cut piece images. `CGImage` is immutable, so sharing across threads is safe.
public struct RenderedPieces: @unchecked Sendable {
    public let images: [CGImage]
    /// Integral pixel frames (top-left origin) of each image on the board bitmap.
    public let rects: [CGRect]
    public let boardPixelSize: CGSize
}

public enum PieceImageRenderer {
    /// Cuts `source` (the whole board) into piece images. Runs off the main thread.
    public static func render(source: CGImage, layout: PuzzleLayout) -> RenderedPieces? {
        let board = CGSize(width: source.width, height: source.height)
        let geometry = PieceGeometry(layout: layout, boardSize: board)
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        let edgeWidth = max(1, geometry.baseLength * 0.03)

        var images: [CGImage] = []
        var rects: [CGRect] = []
        images.reserveCapacity(layout.grid.count)
        rects.reserveCapacity(layout.grid.count)

        for index in 0..<layout.grid.count {
            if Task.isCancelled { return nil }
            let rect = geometry.paddedRect(for: index).integral
            guard let context = CGContext(
                data: nil,
                width: Int(rect.width),
                height: Int(rect.height),
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return nil }

            context.interpolationQuality = .high
            // Board coordinates are top-left; CoreGraphics bitmaps are bottom-left.
            let flip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: -rect.minX, ty: rect.maxY)
            let outline = geometry.path(for: index, transform: flip)

            context.addPath(outline)
            context.clip()
            context.draw(source, in: CGRect(x: -rect.minX, y: rect.maxY - board.height, width: board.width, height: board.height))

            // Soft light rim (half of the stroke is clipped away → inner bevel).
            context.addPath(outline)
            context.setStrokeColor(CGColor(gray: 1, alpha: 0.35))
            context.setLineWidth(edgeWidth * 2)
            context.strokePath()

            guard let image = context.makeImage() else { return nil }
            images.append(image)
            rects.append(rect)
        }
        return RenderedPieces(images: images, rects: rects, boardPixelSize: board)
    }
}

/// Keeps one bitmap of all placed pieces, so the board draws a single image per frame
/// regardless of piece count. Main-actor confined by its owner.
public final class BoardCompositor {
    private let context: CGContext
    private let pieces: RenderedPieces

    public init?(pieces: RenderedPieces) {
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: Int(pieces.boardPixelSize.width),
                height: Int(pieces.boardPixelSize.height),
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              )
        else { return nil }
        self.context = context
        self.pieces = pieces
    }

    public func draw(piece index: Int) {
        guard pieces.images.indices.contains(index) else { return }
        let rect = pieces.rects[index]
        let flipped = CGRect(
            x: rect.minX,
            y: pieces.boardPixelSize.height - rect.maxY,
            width: rect.width,
            height: rect.height
        )
        context.draw(pieces.images[index], in: flipped)
    }

    public func makeImage() -> CGImage? {
        context.makeImage()
    }
}
#endif

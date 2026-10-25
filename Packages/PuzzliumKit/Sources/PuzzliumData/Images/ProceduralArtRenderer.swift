import CoreGraphics
import Foundation
import PuzzliumDomain

/// Draws the built-in illustrations on device, so bundled puzzles cost zero download and zero app size.
/// Scenes are authored on a 400×300 canvas and center-cropped to a square.
enum ProceduralArtRenderer {
    static func render(style: ArtStyle, variant: Int, pixelSize: Int) -> CGImage? {
        guard pixelSize > 0,
              let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: pixelSize,
                height: pixelSize,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              )
        else { return nil }

        let size = CGFloat(pixelSize)
        let scale = size / 300
        // Top-left origin, then fit the 400×300 scene's height and crop the sides.
        context.translateBy(x: 0, y: size)
        context.scaleBy(x: 1, y: -1)
        context.translateBy(x: (size - 400 * scale) / 2, y: 0)
        context.scaleBy(x: scale, y: scale)

        let palette = Palette(style: style, variant: variant)
        switch style {
        case .dunes: drawDunes(context, palette)
        case .lake: drawLake(context, palette)
        case .city: drawCity(context, palette)
        case .bloom: drawBloom(context, palette)
        }
        return context.makeImage()
    }

    // MARK: - Scenes

    private static func drawDunes(_ c: CGContext, _ p: Palette) {
        fill(c, CGPath(rect: CGRect(x: 0, y: 0, width: 400, height: 300), transform: nil), p[0])
        fill(c, CGPath(ellipseIn: CGRect(x: 241, y: 61, width: 88, height: 88), transform: nil), p[1])
        fill(c, hill(start: 180, [(80, 140, 150, 160, 220, 188), (290, 214, 340, 172, 400, 162)]), p[2])
        fill(c, hill(start: 232, [(90, 198, 170, 208, 250, 238), (320, 262, 360, 234, 400, 226)]), p[3])
        fill(c, hill(start: 272, [(120, 252, 230, 258, 400, 276)]), p[4])
    }

    private static func drawLake(_ c: CGContext, _ p: Palette) {
        fill(c, CGPath(rect: CGRect(x: 0, y: 0, width: 400, height: 300), transform: nil), p[0])
        fill(c, CGPath(ellipseIn: CGRect(x: 230, y: 50, width: 60, height: 60), transform: nil), p[1])
        fill(c, polygon([(0, 170), (90, 90), (160, 150), (240, 70), (330, 150), (400, 110), (400, 190), (0, 190)]), p[2])
        fill(c, polygon([(0, 190), (70, 140), (140, 185), (220, 130), (300, 185), (400, 150), (400, 200), (0, 200)]), p[3])
        fill(c, CGPath(rect: CGRect(x: 0, y: 198, width: 400, height: 102), transform: nil), p[4])
        for (x, y, w) in [(60.0, 224.0, 120.0), (230, 254, 90), (120, 276, 70)] {
            fill(c, CGPath(roundedRect: CGRect(x: x, y: y, width: w, height: 4), cornerWidth: 2, cornerHeight: 2, transform: nil), p[5])
        }
    }

    private static func drawCity(_ c: CGContext, _ p: Palette) {
        fill(c, CGPath(rect: CGRect(x: 0, y: 0, width: 400, height: 300), transform: nil), p[0])
        fill(c, CGPath(ellipseIn: CGRect(x: 274, y: 44, width: 52, height: 52), transform: nil), p[1])
        let buildings: [CGRect] = [
            CGRect(x: 20, y: 150, width: 60, height: 150),
            CGRect(x: 90, y: 110, width: 70, height: 190),
            CGRect(x: 170, y: 170, width: 50, height: 130),
            CGRect(x: 230, y: 130, width: 80, height: 170),
            CGRect(x: 320, y: 180, width: 70, height: 120)
        ]
        for (index, rect) in buildings.enumerated() {
            fill(c, CGPath(rect: rect, transform: nil), index.isMultiple(of: 2) ? p[2] : p[3])
            var row = 0
            var y = rect.minY + 16
            while y + 10 < rect.maxY - 8 {
                var column = 0
                var x = rect.minX + 10
                while x + 8 < rect.maxX - 6 {
                    if (column * 7 + row * 3 + index).isMultiple(of: 3) {
                        fill(c, CGPath(rect: CGRect(x: x, y: y, width: 8, height: 10), transform: nil), p[4])
                    }
                    x += 16
                    column += 1
                }
                y += 22
                row += 1
            }
        }
    }

    private static func drawBloom(_ c: CGContext, _ p: Palette) {
        fill(c, CGPath(rect: CGRect(x: 0, y: 0, width: 400, height: 300), transform: nil), p[0])
        c.setStrokeColor(p[1])
        c.setLineWidth(6)
        c.setLineCap(.round)
        let stems = CGMutablePath()
        stems.move(to: CGPoint(x: 120, y: 300))
        stems.addCurve(to: CGPoint(x: 130, y: 160), control1: CGPoint(x: 118, y: 240), control2: CGPoint(x: 126, y: 200))
        stems.move(to: CGPoint(x: 260, y: 300))
        stems.addCurve(to: CGPoint(x: 250, y: 130), control1: CGPoint(x: 262, y: 250), control2: CGPoint(x: 252, y: 210))
        c.addPath(stems)
        c.strokePath()

        for (x, y, angle) in [(150.0, 230.0, -0.52), (232, 220, 0.52)] {
            var transform = CGAffineTransform(translationX: x, y: y).rotated(by: angle)
            let leaf = CGPath(ellipseIn: CGRect(x: -26, y: -10, width: 52, height: 20), transform: &transform)
            fill(c, leaf, p[1])
        }
        let flowers: [(CGFloat, CGFloat, CGFloat, Int)] = [(130, 140, 34, 2), (250, 110, 42, 3), (340, 210, 22, 2), (60, 90, 18, 3)]
        for (x, y, radius, petal) in flowers {
            fill(c, CGPath(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2), transform: nil), p[petal])
            let core = radius * 0.36
            fill(c, CGPath(ellipseIn: CGRect(x: x - core, y: y - core, width: core * 2, height: core * 2), transform: nil), p[4])
        }
    }

    // MARK: - Helpers

    private static func fill(_ context: CGContext, _ path: CGPath, _ color: CGColor) {
        context.addPath(path)
        context.setFillColor(color)
        context.fillPath()
    }

    private static func polygon(_ points: [(CGFloat, CGFloat)]) -> CGPath {
        let path = CGMutablePath()
        path.addLines(between: points.map { CGPoint(x: $0.0, y: $0.1) })
        path.closeSubpath()
        return path
    }

    /// Curved hill from x = 0 to x = 400, closed to the bottom edge.
    private static func hill(start y: CGFloat, _ curves: [(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)]) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: y))
        for curve in curves {
            path.addCurve(
                to: CGPoint(x: curve.4, y: curve.5),
                control1: CGPoint(x: curve.0, y: curve.1),
                control2: CGPoint(x: curve.2, y: curve.3)
            )
        }
        path.addLine(to: CGPoint(x: 400, y: 300))
        path.addLine(to: CGPoint(x: 0, y: 300))
        path.closeSubpath()
        return path
    }
}

private struct Palette {
    private let colors: [CGColor]

    init(style: ArtStyle, variant: Int) {
        // Rows 0…2 are the bundled catalog, rows 3…5 the autumn event.
        let table: [[UInt32]] = switch style {
        case .dunes: [
            [0xF2C48D, 0xE8672A, 0xD08A4E, 0x9A5530, 0x6E3A22],
            [0xE9A6A1, 0xF4D35E, 0xB5687A, 0x7D3F5C, 0x4A2540],
            [0xCFE3E8, 0xF6B76B, 0xD9B48F, 0xA88663, 0x6B5640],
            [0xF6D7A7, 0xD9482B, 0xE0953F, 0xB5612A, 0x7A3A1C],
            [0x3B2B4F, 0xF2B544, 0xA4583A, 0x7C3F32, 0x4B2630],
            [0xFBE7B5, 0xF08A24, 0xD4A235, 0xA8741F, 0x5E4017]
        ]
        case .lake: [
            [0xBFD8D2, 0xF0D9A8, 0x4F6F68, 0x2E4A44, 0x7FA6A0, 0xDCE9E4],
            [0x1E2A44, 0xEDE6C8, 0x34466B, 0x223152, 0x2E4166, 0x8FA3C9],
            [0xF3DCC2, 0xE8A04B, 0xB4633A, 0x7A3B26, 0xD2A88A, 0xF7EAD9],
            [0xE4DCCF, 0xF3B65B, 0x9C7A62, 0x6E5547, 0xB8A898, 0xF4EEE6],
            [0x2C2340, 0xF4A259, 0x5B3E5E, 0x3E2A47, 0x4A3A63, 0xC59FC9],
            [0xDDE8F0, 0xFFF4E0, 0x8DA3B8, 0x5F7690, 0xA9C0D3, 0xFFFFFF]
        ]
        case .city: [
            [0x1E2440, 0xF3E3B5, 0x2A3159, 0x3A4270, 0xE3A13A],
            [0xF2A07B, 0xFFE3B0, 0x5B3A5E, 0x7A4B70, 0xFFD166],
            [0xAFD3EE, 0xFFFFFF, 0x6C7A8F, 0x8C9AAF, 0xF5F7FA],
            [0x2B1E33, 0xF6D28B, 0x4A2E3F, 0x5E3A4D, 0xF39C34],
            [0x8C9AA6, 0xE9EEF2, 0x4F5B66, 0x65717C, 0xF2C46D],
            [0x10172B, 0xF9E7B0, 0x7A2E2A, 0x9C3F2F, 0xFFC857]
        ]
        case .bloom: [
            [0xF3D9DC, 0x3E7A5A, 0xD9576B, 0xB8435A, 0xF2C48D],
            [0xDCEBF5, 0x2F6B5E, 0x5B7FD6, 0x3D5BB0, 0xF7D774],
            [0xFBF1D6, 0x4D7A3A, 0xE88B3A, 0xC8602A, 0x6B3E26],
            [0xF7E6C4, 0x6B7A2E, 0xE0702A, 0xB8461F, 0x5A2E14],
            [0xEDE3D6, 0x55623A, 0xC0392B, 0x8E2A2A, 0xF2C14E],
            [0xE6EEF3, 0x5E7B85, 0xFFFFFF, 0xBFD3DF, 0x7F9CAD]
        ]
        }
        let row = table[((variant % table.count) + table.count) % table.count]
        colors = row.map { hex in
            CGColor(
                srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        }
    }

    subscript(index: Int) -> CGColor {
        colors[min(index, colors.count - 1)]
    }
}

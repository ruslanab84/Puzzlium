import Foundation
import Testing
@testable import PuzzliumEngine

@Suite("PuzzleLayout")
struct PuzzleLayoutTests {
    @Test("Same seed produces the same cut")
    func deterministic() {
        let a = PuzzleLayout.generate(grid: .square(8), seed: 42)
        let b = PuzzleLayout.generate(grid: .square(8), seed: 42)
        #expect(a == b)
        #expect(a != PuzzleLayout.generate(grid: .square(8), seed: 43))
    }

    @Test("Outer edges are flat, inner edges interlock", arguments: [6, 8, 15, 20])
    func interlocking(side: Int) {
        let grid = GridSize.square(side)
        let layout = PuzzleLayout.generate(grid: grid, seed: StableHash.seed("p", "\(side)"))
        for index in 0..<grid.count {
            let row = grid.row(of: index), column = grid.column(of: index)
            let edges = layout.edges[index]
            #expect((row == 0) == (edges.top == .flat))
            #expect((column == 0) == (edges.left == .flat))
            #expect((row == side - 1) == (edges.bottom == .flat))
            #expect((column == side - 1) == (edges.right == .flat))
            if column < side - 1 { #expect(layout.edges[index + 1].left == edges.right.opposite) }
            if row < side - 1 { #expect(layout.edges[index + side].top == edges.bottom.opposite) }
        }
    }

    @Test("Border piece count is 4n − 4")
    func borderCount() {
        let layout = PuzzleLayout.generate(grid: .square(10), seed: 1)
        #expect(layout.edges.filter(\.isBorder).count == 36)
        #expect(layout.edges.filter { $0.flatCount == 2 }.count == 4)
    }
}

@Suite("PieceGeometry")
struct PieceGeometryTests {
    private func points(_ elements: [OutlineElement]) -> [CGPoint] {
        elements.compactMap {
            switch $0 {
            case let .move(p), let .line(p): p
            case let .curve(p, _, _): p
            case .close: nil
            }
        }
    }

    private func contains(_ list: [CGPoint], _ target: CGPoint) -> Bool {
        list.contains { abs($0.x - target.x) < 0.0001 && abs($0.y - target.y) < 0.0001 }
    }

    @Test("Neighbours share the exact knob apex")
    func sharedEdges() {
        let layout = PuzzleLayout.generate(grid: .square(6), seed: 7)
        let geometry = PieceGeometry(layout: layout, boardSize: CGSize(width: 600, height: 600))
        let depth = geometry.baseLength * PieceGeometry.knobDepth

        for index in 0..<layout.grid.count where layout.grid.column(of: index) < 5 {
            let rect = geometry.cellRect(for: index)
            let sign: CGFloat = layout.edges[index].right == .tab ? 1 : -1
            let apex = CGPoint(x: rect.maxX + sign * depth, y: rect.midY)
            #expect(contains(points(geometry.outline(for: index)), apex))
            #expect(contains(points(geometry.outline(for: index + 1)), apex))
        }
    }

    @Test("Padded rect keeps tabs inside")
    func padding() {
        let layout = PuzzleLayout.generate(grid: .square(8), seed: 3)
        let geometry = PieceGeometry(layout: layout, boardSize: CGSize(width: 800, height: 800))
        for index in 0..<layout.grid.count {
            let padded = geometry.paddedRect(for: index)
            for point in points(geometry.outline(for: index)) {
                #expect(padded.contains(point))
            }
        }
    }
}

@Suite("BoardState")
struct BoardStateTests {
    @Test("New board has every piece in the tray")
    func initialState() {
        let state = BoardState(grid: .square(6), seed: 1, rotationEnabled: false)
        #expect(state.tray.count == 36)
        #expect(Set(state.tray).count == 36)
        #expect(state.placedCount == 0)
        #expect(state.rotations.isEmpty)
    }

    @Test("Rotated pieces must be turned upright before placing")
    func rotationGate() throws {
        var state = BoardState(grid: .square(6), seed: 9, rotationEnabled: true)
        let rotated = try #require(state.rotations.keys.first)
        let placedWhileRotated = state.place(rotated)
        #expect(!placedWhileRotated)
        while state.rotation(of: rotated) != 0 { state.rotate(rotated) }
        let placedUpright = state.place(rotated)
        #expect(placedUpright)
        #expect(state.placed.contains(rotated))
        #expect(!state.tray.contains(rotated))
    }

    @Test("Placing every piece completes the board")
    func completion() {
        var state = BoardState(grid: .square(6), seed: 2, rotationEnabled: true)
        for piece in state.tray { state.forcePlace(piece, countsAsHint: false) }
        #expect(state.isComplete)
        #expect(state.fraction == 1)
        #expect(state.hintsUsed == 0)
    }

    @Test("Tray filters split border and inner pieces")
    func filters() {
        let state = BoardState(grid: .square(8), seed: 4, rotationEnabled: false)
        let layout = PuzzleLayout.generate(grid: state.grid, seed: state.seed)
        #expect(state.trayPieces(.edges, layout: layout).count == 28)
        #expect(state.trayPieces(.inner, layout: layout).count == 36)
    }

    @Test("Missed drops stay on the board until placed or returned")
    func loosePieces() {
        var state = BoardState(grid: .square(4), seed: 3, rotationEnabled: false)
        let first = state.tray[0], second = state.tray[1]
        state.drop(first, at: CGPoint(x: 0, y: 2))
        state.drop(second, at: CGPoint(x: 0.5, y: 0.5))
        #expect(!state.tray.contains(first))
        #expect(state.loose.map(\.piece) == [first, second])
        // Clamped so the cell stays on the board.
        #expect(state.loose[0].center == CGPoint(x: 0.125, y: 0.875))

        state.drop(first, at: CGPoint(x: 0.3, y: 0.3))
        #expect(state.loose.map(\.piece) == [second, first])

        state.returnToTray(second)
        #expect(state.tray.first == second)
        let placed = state.place(first)
        #expect(placed)
        #expect(state.loose.isEmpty)
        #expect(state.placed.contains(first))
    }

    @Test("Snapshot round-trips")
    func codable() throws {
        var state = BoardState(grid: .square(8), seed: StableHash.seed("lake", "64"), rotationEnabled: true)
        state.forcePlace(state.tray[0], countsAsHint: true)
        state.drop(state.tray[0], at: CGPoint(x: 0.4, y: 0.6))
        state.elapsed = 123.5
        let decoded = try BoardSnapshotCoder.decode(BoardSnapshotCoder.encode(state))
        #expect(decoded == state)
    }
}

@Suite("SnapResolver")
struct SnapResolverTests {
    let geometry = PieceGeometry(
        layout: PuzzleLayout.generate(grid: .square(8), seed: 1),
        boardSize: CGSize(width: 400, height: 400)
    )

    @Test func snapsNearSlot() {
        let center = geometry.center(for: 10)
        let dropped = CGPoint(x: center.x + 10, y: center.y - 8)
        #expect(SnapResolver().shouldSnap(piece: 10, droppedCenter: dropped, rotation: 0, geometry: geometry))
    }

    @Test func rejectsFarDrop() {
        let center = geometry.center(for: 10)
        let dropped = CGPoint(x: center.x + 50, y: center.y)
        #expect(!SnapResolver().shouldSnap(piece: 10, droppedCenter: dropped, rotation: 0, geometry: geometry))
    }

    @Test func rejectsRotatedPiece() {
        #expect(!SnapResolver().shouldSnap(piece: 10, droppedCenter: geometry.center(for: 10), rotation: 1, geometry: geometry))
    }
}

#if canImport(CoreGraphics)
import CoreGraphics

@Suite("Rendering")
struct RenderingTests {
    @Test("Every piece gets an image and the compositor draws them")
    func renderAll() throws {
        let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        let context = try #require(CGContext(data: nil, width: 240, height: 240, bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(CGColor(red: 0.8, green: 0.4, blue: 0.2, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 240, height: 240))
        let source = try #require(context.makeImage())

        let layout = PuzzleLayout.generate(grid: .square(6), seed: 5)
        let pieces = try #require(PieceImageRenderer.render(source: source, layout: layout))
        #expect(pieces.images.count == 36)

        let compositor = try #require(BoardCompositor(pieces: pieces))
        for index in 0..<36 { compositor.draw(piece: index) }
        let composite = try #require(compositor.makeImage())
        #expect(composite.width == 240)
    }
}
#endif

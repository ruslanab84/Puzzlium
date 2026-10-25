import Foundation

public struct GridSize: Hashable, Codable, Sendable {
    public let rows: Int
    public let columns: Int

    public init(rows: Int, columns: Int) {
        precondition(rows > 0 && columns > 0, "Grid must have at least one cell")
        self.rows = rows
        self.columns = columns
    }

    public static func square(_ side: Int) -> GridSize {
        GridSize(rows: side, columns: side)
    }

    public var count: Int { rows * columns }

    public func row(of index: Int) -> Int { index / columns }
    public func column(of index: Int) -> Int { index % columns }
}

public enum EdgeKind: Int8, Codable, Sendable {
    case blank = -1
    case flat = 0
    case tab = 1

    public var opposite: EdgeKind {
        switch self {
        case .blank: .tab
        case .flat: .flat
        case .tab: .blank
        }
    }
}

public struct PieceEdges: Hashable, Codable, Sendable {
    public var top: EdgeKind
    public var right: EdgeKind
    public var bottom: EdgeKind
    public var left: EdgeKind

    public static let allFlat = PieceEdges(top: .flat, right: .flat, bottom: .flat, left: .flat)

    public var flatCount: Int {
        [top, right, bottom, left].filter { $0 == .flat }.count
    }

    public var isBorder: Bool { flatCount > 0 }
}

/// Tab/blank assignment for every piece. Neighbouring edges always interlock.
public struct PuzzleLayout: Hashable, Sendable {
    public let grid: GridSize
    public let seed: UInt64
    public let edges: [PieceEdges]

    public static func generate(grid: GridSize, seed: UInt64) -> PuzzleLayout {
        var rng = SplitMix64(seed: seed)
        var edges = Array(repeating: PieceEdges.allFlat, count: grid.count)

        for row in 0..<grid.rows {
            for column in 0..<grid.columns {
                let index = row * grid.columns + column
                if column < grid.columns - 1 {
                    let kind: EdgeKind = Bool.random(using: &rng) ? .tab : .blank
                    edges[index].right = kind
                    edges[index + 1].left = kind.opposite
                }
                if row < grid.rows - 1 {
                    let kind: EdgeKind = Bool.random(using: &rng) ? .tab : .blank
                    edges[index].bottom = kind
                    edges[index + grid.columns].top = kind.opposite
                }
            }
        }
        return PuzzleLayout(grid: grid, seed: seed, edges: edges)
    }
}

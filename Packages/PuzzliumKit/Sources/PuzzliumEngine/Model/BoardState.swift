import Foundation

public enum TrayFilter: String, CaseIterable, Sendable {
    case all
    case edges
    case inner
}

/// A piece dropped on the board away from its slot. Centre is in unit board coordinates (0…1).
public struct LoosePiece: Codable, Equatable, Sendable {
    public let piece: Int
    public let center: CGPoint
}

/// Complete, serialisable game state. Pure value type: every mutation is explicit and testable.
public struct BoardState: Codable, Equatable, Sendable {
    public static let currentVersion = 2

    public let version: Int
    public let grid: GridSize
    public let seed: UInt64
    public private(set) var placed: Set<Int>
    /// Pieces waiting in the tray, in display order.
    public private(set) var tray: [Int]
    /// Pieces lying on the board outside their slot, bottom to top.
    public private(set) var loose: [LoosePiece]
    /// Quarter turns (1…3) for rotated tray pieces; missing key means upright.
    public private(set) var rotations: [Int: Int]
    public var elapsed: TimeInterval
    public private(set) var hintsUsed: Int

    public init(grid: GridSize, seed: UInt64, rotationEnabled: Bool) {
        var rng = SplitMix64(seed: seed ^ 0x5DEE_CE66_D1CE_F00D)
        version = Self.currentVersion
        self.grid = grid
        self.seed = seed
        placed = []
        tray = Array(0..<grid.count).shuffled(using: &rng)
        loose = []
        var rotations: [Int: Int] = [:]
        if rotationEnabled {
            for piece in 0..<grid.count {
                let turns = Int.random(in: 0...3, using: &rng)
                if turns != 0 { rotations[piece] = turns }
            }
        }
        self.rotations = rotations
        elapsed = 0
        hintsUsed = 0
    }

    public var totalCount: Int { grid.count }
    public var placedCount: Int { placed.count }
    public var isComplete: Bool { placed.count == grid.count }
    public var fraction: Double { Double(placed.count) / Double(max(grid.count, 1)) }

    public func rotation(of piece: Int) -> Int {
        rotations[piece] ?? 0
    }

    /// Not placed yet: either in the tray or loose on the board.
    public func isAvailable(_ piece: Int) -> Bool {
        !placed.contains(piece) && piece >= 0 && piece < grid.count
    }

    public mutating func rotate(_ piece: Int) {
        guard isAvailable(piece) else { return }
        let next = (rotation(of: piece) + 1) % 4
        rotations[piece] = next == 0 ? nil : next
    }

    /// Places a piece if it is upright and not placed yet.
    @discardableResult
    public mutating func place(_ piece: Int) -> Bool {
        guard isAvailable(piece), rotation(of: piece) == 0 else { return false }
        commit(piece)
        return true
    }

    /// Places a piece regardless of rotation (hints, accessibility).
    @discardableResult
    public mutating func forcePlace(_ piece: Int, countsAsHint: Bool) -> Bool {
        guard isAvailable(piece) else { return false }
        rotations[piece] = nil
        commit(piece)
        if countsAsHint { hintsUsed += 1 }
        return true
    }

    /// Leaves the piece on the board at `center` (unit coordinates), on top of other loose pieces.
    /// The centre is clamped so the whole cell stays on the board.
    public mutating func drop(_ piece: Int, at center: CGPoint) {
        guard isAvailable(piece) else { return }
        let halfWidth = 0.5 / CGFloat(grid.columns)
        let halfHeight = 0.5 / CGFloat(grid.rows)
        let clamped = CGPoint(
            x: min(max(center.x, halfWidth), 1 - halfWidth),
            y: min(max(center.y, halfHeight), 1 - halfHeight)
        )
        remove(piece)
        loose.append(LoosePiece(piece: piece, center: clamped))
    }

    /// Moves a loose piece back to the front of the tray.
    public mutating func returnToTray(_ piece: Int) {
        guard loose.contains(where: { $0.piece == piece }) else { return }
        remove(piece)
        tray.insert(piece, at: 0)
    }

    public mutating func shuffleTray(seed: UInt64) {
        var rng = SplitMix64(seed: seed)
        tray.shuffle(using: &rng)
    }

    public func trayPieces(_ filter: TrayFilter, layout: PuzzleLayout) -> [Int] {
        switch filter {
        case .all: tray
        case .edges: tray.filter { layout.edges[$0].isBorder }
        case .inner: tray.filter { !layout.edges[$0].isBorder }
        }
    }

    private mutating func commit(_ piece: Int) {
        remove(piece)
        placed.insert(piece)
    }

    private mutating func remove(_ piece: Int) {
        tray.removeAll { $0 == piece }
        loose.removeAll { $0.piece == piece }
    }
}

public enum BoardSnapshotCoder {
    public static func encode(_ state: BoardState) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try encoder.encode(state)
    }

    public static func decode(_ data: Data) throws -> BoardState {
        let state = try JSONDecoder().decode(BoardState.self, from: data)
        guard state.version == BoardState.currentVersion else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unsupported board version \(state.version)"))
        }
        return state
    }
}

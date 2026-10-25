import Foundation

public enum PieceCount: Int, CaseIterable, Codable, Sendable, Comparable, Identifiable {
    case p36 = 36
    case p64 = 64
    case p100 = 100
    case p144 = 144
    case p225 = 225
    case p400 = 400

    public var id: Int { rawValue }

    /// Pieces per row/column (all boards are square).
    public var side: Int {
        switch self {
        case .p36: 6
        case .p64: 8
        case .p100: 10
        case .p144: 12
        case .p225: 15
        case .p400: 20
        }
    }

    public var estimatedMinutes: Int {
        switch self {
        case .p36: 8
        case .p64: 13
        case .p100: 20
        case .p144: 30
        case .p225: 45
        case .p400: 80
        }
    }

    public static func < (lhs: PieceCount, rhs: PieceCount) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum TableSurface: String, CaseIterable, Codable, Sendable {
    case felt
    case walnut
    case slate
    case linen
}

/// Everything needed to start (or resume) one game.
public struct GameConfiguration: Identifiable, Hashable, Sendable {
    public let puzzle: Puzzle
    public let pieceCount: PieceCount
    public let rotationEnabled: Bool
    public let table: TableSurface
    /// Played from an event: finishing returns to the level list instead of the library.
    public let isEventLevel: Bool

    public init(puzzle: Puzzle, pieceCount: PieceCount, rotationEnabled: Bool, table: TableSurface, isEventLevel: Bool = false) {
        self.puzzle = puzzle
        self.pieceCount = pieceCount
        self.rotationEnabled = rotationEnabled
        self.table = table
        self.isEventLevel = isEventLevel
    }

    public var id: String { "\(puzzle.id)#\(pieceCount.rawValue)#\(rotationEnabled)" }
}

/// Last choices made in setup, restored next time.
public struct GamePreferences: Codable, Hashable, Sendable {
    public var pieceCount: PieceCount
    public var rotationEnabled: Bool
    public var table: TableSurface
    public var showsPreview: Bool

    public init(
        pieceCount: PieceCount = .p64,
        rotationEnabled: Bool = false,
        table: TableSurface = .felt,
        showsPreview: Bool = true
    ) {
        self.pieceCount = pieceCount
        self.rotationEnabled = rotationEnabled
        self.table = table
        self.showsPreview = showsPreview
    }
}

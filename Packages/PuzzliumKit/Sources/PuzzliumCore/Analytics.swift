import Foundation

/// Product events. Parameters never contain personal data.
public enum AnalyticsEvent: Sendable, Equatable {
    case puzzleStarted(puzzleID: String, pieces: Int, rotation: Bool)
    case puzzleResumed(puzzleID: String, pieces: Int)
    case puzzleCompleted(puzzleID: String, pieces: Int, seconds: Int)
    case hintUsed(puzzleID: String)

    public var name: String {
        switch self {
        case .puzzleStarted: "puzzle_started"
        case .puzzleResumed: "puzzle_resumed"
        case .puzzleCompleted: "puzzle_completed"
        case .hintUsed: "hint_used"
        }
    }

    public var parameters: [String: String] {
        switch self {
        case let .puzzleStarted(id, pieces, rotation):
            ["puzzle_id": id, "pieces": String(pieces), "rotation": String(rotation)]
        case let .puzzleResumed(id, pieces):
            ["puzzle_id": id, "pieces": String(pieces)]
        case let .puzzleCompleted(id, pieces, seconds):
            ["puzzle_id": id, "pieces": String(pieces), "seconds": String(seconds)]
        case let .hintUsed(id):
            ["puzzle_id": id]
        }
    }
}

/// Analytics boundary. Firebase (or any vendor) is plugged in behind this protocol.
public protocol AnalyticsTracking: Sendable {
    func track(_ event: AnalyticsEvent)
}

/// Default tracker: writes events to the unified log (debug builds, previews, tests).
public struct LogAnalyticsTracker: AnalyticsTracking {
    public init() {}

    public func track(_ event: AnalyticsEvent) {
        Log.analytics.debug("event \(event.name, privacy: .public)")
    }
}

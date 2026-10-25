import OSLog

/// Central loggers. Never log user content or identifiers with `.public` privacy.
public enum Log {
    private static let subsystem = "com.puzzlium.app"

    public static let game = Logger(subsystem: subsystem, category: "game")
    public static let data = Logger(subsystem: subsystem, category: "data")
    public static let ui = Logger(subsystem: subsystem, category: "ui")
    public static let analytics = Logger(subsystem: subsystem, category: "analytics")
}

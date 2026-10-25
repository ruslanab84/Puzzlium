import Foundation
import PuzzliumDomain

public struct UserDefaultsPreferencesRepository: PreferencesRepository {
    private static let key = "pz.preferences.v1"
    private let suiteName: String?

    public init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }

    private var defaults: UserDefaults {
        suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
    }

    public func load() -> GamePreferences {
        guard let data = defaults.data(forKey: Self.key),
              let preferences = try? JSONDecoder().decode(GamePreferences.self, from: data)
        else { return GamePreferences() }
        return preferences
    }

    public func save(_ preferences: GamePreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults.set(data, forKey: Self.key)
    }
}

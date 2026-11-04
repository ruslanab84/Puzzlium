import Foundation

/// Which catalog pictures sit behind a pack purchase. Every category keeps its first few
/// pictures free as a sample; the player's own photos and anything already started stay open.
public struct PackAccess: Sendable, Equatable {
    public static let freePerCategory = 3

    public var owned: Set<PuzzleCategory>
    /// The "all packs" purchase, which also covers categories added later.
    public var ownsAll: Bool
    /// Single pictures opened by watching a rewarded ad.
    public var adUnlocked: Set<String>

    public init(owned: Set<PuzzleCategory> = [], ownsAll: Bool = false, adUnlocked: Set<String> = []) {
        self.owned = owned
        self.ownsAll = ownsAll
        self.adUnlocked = adUnlocked
    }

    /// Anyone who bought a pack never sees banners or interstitials.
    public var hasPurchased: Bool { ownsAll || !owned.isEmpty }

    public func isUnlocked(_ category: PuzzleCategory) -> Bool {
        ownsAll || category == .photos || owned.contains(category)
    }

    /// IDs of entries the player can't open yet. Order within a category decides the free sample.
    public func lockedIDs(in entries: [PuzzleEntry]) -> Set<String> {
        var seen: [PuzzleCategory: Int] = [:]
        var locked = Set<String>()
        for entry in entries {
            let category = entry.puzzle.category
            let position = seen[category, default: 0]
            seen[category] = position + 1
            if !isUnlocked(category), position >= Self.freePerCategory, entry.status == .notStarted,
               !adUnlocked.contains(entry.puzzle.id) {
                locked.insert(entry.puzzle.id)
            }
        }
        return locked
    }
}

import Foundation
import Observation
import PuzzliumCore
import PuzzliumDomain
import StoreKit

/// Category packs sold as non-consumable in-app purchases, plus one "all packs" purchase.
/// Ownership is read from StoreKit's entitlements (cached on device, so it works offline);
/// nothing is stored by the app.
@Observable
@MainActor
final class PackStore {
    nonisolated static let allPacksID = "RuslanAbd.Puzzlium.pack.all"

    nonisolated static func productID(for category: PuzzleCategory) -> String {
        "RuslanAbd.Puzzlium.pack.\(category.rawValue)"
    }

    private(set) var access = PackAccess()
    private(set) var products: [String: Product] = [:]
    private(set) var isPurchasing = false

    func product(for category: PuzzleCategory) -> Product? { products[Self.productID(for: category)] }
    var allPacks: Product? { products[Self.allPacksID] }

    /// Loads ownership and prices, then follows transactions (Ask to Buy, refunds, other devices)
    /// for as long as the calling task lives.
    func run() async {
        await refreshEntitlements()
        let ids = PuzzleCategory.allCases.filter { $0 != .photos }.map(Self.productID) + [Self.allPacksID]
        do {
            products = Dictionary(uniqueKeysWithValues: try await Product.products(for: ids).map { ($0.id, $0) })
        } catch {
            Log.ui.error("Loading products failed: \(String(describing: error), privacy: .public)")
        }
        for await update in Transaction.updates {
            if case let .verified(transaction) = update { await transaction.finish() }
            await refreshEntitlements()
        }
    }

    /// Cancelled and pending (Ask to Buy) purchases just return; approval arrives via `Transaction.updates`.
    func purchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            guard case let .success(.verified(transaction)) = try await product.purchase() else { return }
            await transaction.finish()
            await refreshEntitlements()
        } catch {
            Log.ui.error("Purchase failed: \(String(describing: error), privacy: .public)")
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
        } catch {
            Log.ui.error("Restore failed: \(String(describing: error), privacy: .public)")
        }
        await refreshEntitlements()
    }

    /// Keeps a picture opened by a rewarded ad. Stored locally; reinstalling locks it again.
    func unlockWithAd(_ puzzleID: String) {
        access.adUnlocked.insert(puzzleID)
        UserDefaults.standard.set(Array(access.adUnlocked), forKey: Self.adUnlockedKey)
    }

    private static let adUnlockedKey = "adUnlockedPuzzles"

    private func refreshEntitlements() async {
        var access = PackAccess(adUnlocked: Set(UserDefaults.standard.stringArray(forKey: Self.adUnlockedKey) ?? []))
        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result, transaction.revocationDate == nil else { continue }
            if transaction.productID == Self.allPacksID {
                access.ownsAll = true
            } else if let category = PuzzleCategory.allCases.first(where: { Self.productID(for: $0) == transaction.productID }) {
                access.owned.insert(category)
            }
        }
        self.access = access
    }
}

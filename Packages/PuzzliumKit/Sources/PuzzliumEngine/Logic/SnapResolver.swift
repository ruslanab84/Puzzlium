import Foundation

/// Decides whether a dropped piece lands in its slot.
public struct SnapResolver: Sendable {
    /// Allowed distance from the slot centre, as a share of the cell's shorter side.
    public let toleranceRatio: CGFloat

    public init(toleranceRatio: CGFloat = 0.4) {
        self.toleranceRatio = toleranceRatio
    }

    public func shouldSnap(piece: Int, droppedCenter: CGPoint, rotation: Int, geometry: PieceGeometry) -> Bool {
        guard rotation % 4 == 0 else { return false }
        let target = geometry.center(for: piece)
        let distance = hypot(droppedCenter.x - target.x, droppedCenter.y - target.y)
        return distance <= geometry.baseLength * toleranceRatio
    }
}

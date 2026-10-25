import Foundation

public enum OutlineElement: Equatable, Sendable {
    case move(CGPoint)
    case line(CGPoint)
    case curve(to: CGPoint, control1: CGPoint, control2: CGPoint)
    case close
}

/// Converts a layout into piece outlines for a given board size (top-left origin).
public struct PieceGeometry: Sendable {
    /// Space around a cell that fits the tab (depth 0.24) plus an edge stroke.
    public static let marginRatio: CGFloat = 0.26

    /// One knob drawn along an edge: x = position along the edge (0…1),
    /// y = outward offset in units of the cell's shorter side. Symmetric around x = 0.5,
    /// so neighbours traversing the same edge in opposite directions get identical curves.
    struct KnobSegment: Sendable {
        let control1: CGPoint
        let control2: CGPoint
        let end: CGPoint
    }

    static let knobStart = CGPoint(x: 0.36, y: 0)
    static let knob: [KnobSegment] = [
        KnobSegment(control1: CGPoint(x: 0.40, y: 0.00), control2: CGPoint(x: 0.44, y: 0.04), end: CGPoint(x: 0.42, y: 0.08)),
        KnobSegment(control1: CGPoint(x: 0.36, y: 0.14), control2: CGPoint(x: 0.38, y: 0.24), end: CGPoint(x: 0.50, y: 0.24)),
        KnobSegment(control1: CGPoint(x: 0.62, y: 0.24), control2: CGPoint(x: 0.64, y: 0.14), end: CGPoint(x: 0.58, y: 0.08)),
        KnobSegment(control1: CGPoint(x: 0.56, y: 0.04), control2: CGPoint(x: 0.60, y: 0.00), end: CGPoint(x: 0.64, y: 0.00))
    ]
    public static let knobDepth: CGFloat = 0.24

    public let layout: PuzzleLayout
    public let boardSize: CGSize

    public init(layout: PuzzleLayout, boardSize: CGSize) {
        self.layout = layout
        self.boardSize = boardSize
    }

    public var cellSize: CGSize {
        CGSize(
            width: boardSize.width / CGFloat(layout.grid.columns),
            height: boardSize.height / CGFloat(layout.grid.rows)
        )
    }

    public var baseLength: CGFloat { min(cellSize.width, cellSize.height) }

    public var margin: CGFloat { baseLength * Self.marginRatio }

    public func cellRect(for index: Int) -> CGRect {
        let size = cellSize
        return CGRect(
            x: CGFloat(layout.grid.column(of: index)) * size.width,
            y: CGFloat(layout.grid.row(of: index)) * size.height,
            width: size.width,
            height: size.height
        )
    }

    public func center(for index: Int) -> CGPoint {
        let rect = cellRect(for: index)
        return CGPoint(x: rect.midX, y: rect.midY)
    }

    /// Cell plus margin on every side: the frame of a rendered piece image.
    public func paddedRect(for index: Int) -> CGRect {
        cellRect(for: index).insetBy(dx: -margin, dy: -margin)
    }

    public func outline(for index: Int) -> [OutlineElement] {
        let rect = cellRect(for: index)
        let edges = layout.edges[index]
        let topLeft = CGPoint(x: rect.minX, y: rect.minY)
        let topRight = CGPoint(x: rect.maxX, y: rect.minY)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)

        var elements: [OutlineElement] = [.move(topLeft)]
        appendEdge(to: &elements, from: topLeft, to: topRight, normal: CGVector(dx: 0, dy: -1), kind: edges.top)
        appendEdge(to: &elements, from: topRight, to: bottomRight, normal: CGVector(dx: 1, dy: 0), kind: edges.right)
        appendEdge(to: &elements, from: bottomRight, to: bottomLeft, normal: CGVector(dx: 0, dy: 1), kind: edges.bottom)
        appendEdge(to: &elements, from: bottomLeft, to: topLeft, normal: CGVector(dx: -1, dy: 0), kind: edges.left)
        elements.append(.close)
        return elements
    }

    private func appendEdge(
        to elements: inout [OutlineElement],
        from start: CGPoint,
        to end: CGPoint,
        normal: CGVector,
        kind: EdgeKind
    ) {
        guard kind != .flat else {
            elements.append(.line(end))
            return
        }
        let depth = baseLength * CGFloat(kind.rawValue)

        func map(_ point: CGPoint) -> CGPoint {
            CGPoint(
                x: start.x + (end.x - start.x) * point.x + normal.dx * point.y * depth,
                y: start.y + (end.y - start.y) * point.x + normal.dy * point.y * depth
            )
        }

        elements.append(.line(map(Self.knobStart)))
        for segment in Self.knob {
            elements.append(.curve(to: map(segment.end), control1: map(segment.control1), control2: map(segment.control2)))
        }
        elements.append(.line(end))
    }
}

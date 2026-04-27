import Foundation

public enum GridMath {
    public static let cellSize: CGFloat = 40

    /// Snaps a free-form point to the nearest grid cell origin.
    public static func snap(point: CGPoint, cellSize: CGFloat = GridMath.cellSize) -> GridPoint {
        let col = Int(round(point.x / cellSize))
        let row = Int(round(point.y / cellSize))
        return GridPoint(col: max(0, col), row: max(0, row))
    }

    /// Converts a GridPoint + WidgetSize to a GridRect.
    public static func rect(for origin: GridPoint, size: WidgetSize) -> GridRect {
        GridRect(origin: origin, widgetSize: size)
    }

    /// Returns true if two GridRects overlap.
    public static func collides(_ a: GridRect, with b: GridRect) -> Bool {
        a.intersects(b)
    }

    /// Finds the first free grid cell for a given size, given existing placements.
    /// Scans left-to-right, top-to-bottom until a non-colliding slot is found.
    public static func firstFreeSlot(
        for size: WidgetSize,
        in gridCols: Int = 12,
        existing: [GridRect]
    ) -> GridPoint {
        let (cols, rows) = size.gridCells
        var row = 0
        while row < 100 {
            for col in 0...(max(0, gridCols - cols)) {
                let candidate = GridRect(origin: GridPoint(col: col, row: row), widgetSize: size)
                if !existing.contains(where: { $0.intersects(candidate) }) {
                    return candidate.origin
                }
            }
            row += 1
        }
        return .zero
    }
}

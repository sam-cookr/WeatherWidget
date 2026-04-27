import Foundation

public struct GridPoint: Codable, Hashable, Equatable {
    public var col: Int
    public var row: Int

    public init(col: Int, row: Int) {
        self.col = col
        self.row = row
    }

    public static let zero = GridPoint(col: 0, row: 0)
}

public struct GridRect: Codable, Equatable {
    public var origin: GridPoint
    public var sizeCols: Int
    public var sizeRows: Int

    public var endCol: Int { origin.col + sizeCols }
    public var endRow: Int { origin.row + sizeRows }

    public init(origin: GridPoint, widgetSize: WidgetSize) {
        self.origin = origin
        let cells = widgetSize.gridCells
        self.sizeCols = cells.cols
        self.sizeRows = cells.rows
    }

    public init(origin: GridPoint, cols: Int, rows: Int) {
        self.origin = origin
        self.sizeCols = cols
        self.sizeRows = rows
    }

    public func contains(_ point: GridPoint) -> Bool {
        point.col >= origin.col && point.col < endCol &&
        point.row >= origin.row && point.row < endRow
    }

    public func intersects(_ other: GridRect) -> Bool {
        origin.col < other.endCol && endCol > other.origin.col &&
        origin.row < other.endRow && endRow > other.origin.row
    }
}

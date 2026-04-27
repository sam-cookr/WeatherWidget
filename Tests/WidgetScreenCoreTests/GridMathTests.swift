import XCTest
@testable import WidgetScreenCore

final class GridMathTests: XCTestCase {
    func testSnapToGrid() {
        let point = CGPoint(x: 55, y: 85)
        let snapped = GridMath.snap(point: point, cellSize: 40)
        XCTAssertEqual(snapped.col, 1)
        XCTAssertEqual(snapped.row, 2)
    }

    func testNoCollision() {
        let a = GridRect(origin: GridPoint(col: 0, row: 0), widgetSize: .medium) // 4x2
        let b = GridRect(origin: GridPoint(col: 0, row: 2), widgetSize: .medium) // 4x2, below
        XCTAssertFalse(GridMath.collides(a, with: b))
    }

    func testCollision() {
        let a = GridRect(origin: GridPoint(col: 0, row: 0), widgetSize: .medium) // 4x2
        let b = GridRect(origin: GridPoint(col: 2, row: 1), widgetSize: .small)  // overlaps
        XCTAssertTrue(GridMath.collides(a, with: b))
    }

    func testFirstFreeSlotNoExisting() {
        let slot = GridMath.firstFreeSlot(for: .medium, in: 12, existing: [])
        XCTAssertEqual(slot, GridPoint.zero)
    }

    func testFirstFreeSlotSkipsOccupied() {
        let existing = [GridRect(origin: GridPoint(col: 0, row: 0), widgetSize: .medium)]
        let slot = GridMath.firstFreeSlot(for: .medium, in: 12, existing: existing)
        // (0,0) is taken, next should be (4,0) or (0,2)
        XCTAssertNotEqual(slot, GridPoint.zero)
    }
}

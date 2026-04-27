import XCTest
@testable import WidgetScreenWindowing
import WidgetScreenCore

final class WindowManagerDiffingTests: XCTestCase {
    func testNothingToAdd() {
        let instance = WidgetInstance(typeID: "weather", size: .medium, gridOrigin: .zero)
        let (toAdd, toRemove) = WindowManager.diff(
            newInstances: [instance],
            existingIDs: [instance.id]
        )
        XCTAssertTrue(toAdd.isEmpty)
        XCTAssertTrue(toRemove.isEmpty)
    }

    func testAddsNewInstance() {
        let instance = WidgetInstance(typeID: "weather", size: .medium, gridOrigin: .zero)
        let (toAdd, toRemove) = WindowManager.diff(
            newInstances: [instance],
            existingIDs: []
        )
        XCTAssertEqual(toAdd.map(\.id), [instance.id])
        XCTAssertTrue(toRemove.isEmpty)
    }

    func testRemovesStaleWindow() {
        let staleID = UUID()
        let (toAdd, toRemove) = WindowManager.diff(
            newInstances: [],
            existingIDs: [staleID]
        )
        XCTAssertTrue(toAdd.isEmpty)
        XCTAssertEqual(toRemove, [staleID])
    }

    func testAddAndRemoveSimultaneously() {
        let existing = WidgetInstance(typeID: "battery", size: .small, gridOrigin: .zero)
        let incoming = WidgetInstance(typeID: "weather", size: .medium, gridOrigin: .zero)
        let (toAdd, toRemove) = WindowManager.diff(
            newInstances: [incoming],
            existingIDs: [existing.id]
        )
        XCTAssertEqual(toAdd.map(\.id), [incoming.id])
        XCTAssertEqual(toRemove, [existing.id])
    }
}

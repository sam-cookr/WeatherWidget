import XCTest
@testable import WidgetScreenCore

@MainActor
final class LayoutStoreTests: XCTestCase {
    private func freshStore() -> LayoutStore {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-layout-\(UUID().uuidString).json")
        return LayoutStore(storageURL: url, defaultsKey: "test.layout.\(UUID().uuidString)")
    }

    func testAddAndRemove() {
        let store = freshStore()
        let instance = WidgetInstance(typeID: "weather", size: .medium, gridOrigin: GridPoint(col: 0, row: 0))
        store.add(instance)
        XCTAssertEqual(store.instances.count, 1)
        store.remove(id: instance.id)
        XCTAssertEqual(store.instances.count, 0)
    }

    func testUpdate() {
        let store = freshStore()
        var instance = WidgetInstance(typeID: "weather", size: .medium, gridOrigin: GridPoint(col: 0, row: 0))
        store.add(instance)
        instance.gridOrigin = GridPoint(col: 4, row: 2)
        store.update(instance)
        XCTAssertEqual(store.instances.first?.gridOrigin, GridPoint(col: 4, row: 2))
    }

    func testRevalidateRemovesStaleScreen() {
        let store = freshStore()
        let instance = WidgetInstance(typeID: "battery", size: .small,
                                      gridOrigin: .zero, targetScreen: "OldScreen")
        store.add(instance)
        store.revalidate(availableScreenNames: ["MainDisplay"])
        XCTAssertNil(store.instances.first?.targetScreen)
    }
}

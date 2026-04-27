import Foundation
import Combine

public struct WidgetInstance: Codable, Identifiable, Hashable {
    public var id: UUID
    public var typeID: String
    public var size: WidgetSize
    public var gridOrigin: GridPoint
    public var targetScreen: String?

    public init(id: UUID = UUID(), typeID: String, size: WidgetSize = .medium, gridOrigin: GridPoint = .zero, targetScreen: String? = nil) {
        self.id = id
        self.typeID = typeID
        self.size = size
        self.gridOrigin = gridOrigin
        self.targetScreen = targetScreen
    }
}

/// Persists the layout to Application Support and a UserDefaults mirror for fast boot.
@MainActor
public final class LayoutStore: ObservableObject {
    public static let shared = LayoutStore()

    @Published public var instances: [WidgetInstance] = []

    private let layoutURL: URL
    private let defaultsKey: String

    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("WidgetScreen", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.layoutURL = dir.appendingPathComponent("layout.json")
        self.defaultsKey = "ws.layout.mirror"
        load()
    }

    /// Isolated initializer for tests — uses a temp file and unique key, starts empty.
    public init(storageURL: URL, defaultsKey: String) {
        self.layoutURL = storageURL
        self.defaultsKey = defaultsKey
    }

    public func add(_ instance: WidgetInstance) {
        instances.append(instance)
        persist()
    }

    public func remove(id: UUID) {
        instances.removeAll { $0.id == id }
        persist()
    }

    public func update(_ instance: WidgetInstance) {
        if let idx = instances.firstIndex(where: { $0.id == instance.id }) {
            instances[idx] = instance
            persist()
        }
    }

    public func revalidate(availableScreenNames: [String]) {
        var changed = false
        for i in instances.indices {
            if let screen = instances[i].targetScreen, !availableScreenNames.contains(screen) {
                instances[i].targetScreen = nil
                changed = true
            }
        }
        if changed { persist() }
    }

    private func load() {
        // Try disk first, fall back to UserDefaults mirror
        if let data = try? Data(contentsOf: layoutURL),
           let decoded = try? JSONDecoder().decode([WidgetInstance].self, from: data) {
            instances = decoded
            return
        }
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode([WidgetInstance].self, from: data) {
            instances = decoded
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(instances) else { return }
        try? data.write(to: layoutURL, options: .atomic)
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}

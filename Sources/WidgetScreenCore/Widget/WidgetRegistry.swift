import Foundation

/// Central registry of all available widget factories.
/// Populated at app startup by registering `AnyWidgetFactory` instances.
public final class WidgetRegistry {
    public static let shared = WidgetRegistry()

    private var factories: [String: AnyWidgetFactory] = [:]

    public func register(_ factory: AnyWidgetFactory) {
        factories[factory.id] = factory
    }

    public func factory(for id: String) -> AnyWidgetFactory? {
        factories[id]
    }

    public var all: [AnyWidgetFactory] {
        factories.values.sorted { $0.displayName < $1.displayName }
    }
}

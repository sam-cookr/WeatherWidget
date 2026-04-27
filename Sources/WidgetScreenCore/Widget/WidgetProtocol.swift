import SwiftUI

/// The size/tier of a widget instance.
/// Added here in M5 as a new type. The app's existing `WidgetSize` in SettingsStore
/// (compact/standard/large) is separate and will be removed in M7 when Weather
/// migrates to this protocol. Until then, use `WidgetScreenCore.WidgetSize`
/// to disambiguate if needed.
public enum WidgetSize: String, Codable, CaseIterable, Hashable {
    case small, medium, large

    public var gridCells: (cols: Int, rows: Int) {
        switch self {
        case .small:  return (2, 2)
        case .medium: return (4, 2)
        case .large:  return (4, 4)
        }
    }

    public var label: String { rawValue.capitalized }
}

public protocol WidgetProtocol {
    static var id: String { get }
    static var displayName: String { get }
    static var iconSymbol: String { get }
    static var supportedSizes: [WidgetSize] { get }
}

/// Type-erased factory stored in the registry.
public struct AnyWidgetFactory {
    public let id: String
    public let displayName: String
    public let iconSymbol: String
    public let supportedSizes: [WidgetSize]

    public let makeProvider: () -> AnyObject
    public let makeAnyView: (WidgetSize, AnyObject) -> AnyView
    public let makeAnySettingsView: (AnyObject) -> AnyView

    public init(
        id: String,
        displayName: String,
        iconSymbol: String,
        supportedSizes: [WidgetSize],
        makeProvider: @escaping () -> AnyObject,
        makeAnyView: @escaping (WidgetSize, AnyObject) -> AnyView,
        makeAnySettingsView: @escaping (AnyObject) -> AnyView
    ) {
        self.id = id
        self.displayName = displayName
        self.iconSymbol = iconSymbol
        self.supportedSizes = supportedSizes
        self.makeProvider = makeProvider
        self.makeAnyView = makeAnyView
        self.makeAnySettingsView = makeAnySettingsView
    }
}

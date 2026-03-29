import Foundation
import Combine

// MARK: - Setting Option Protocol

protocol SettingOption: Hashable {
    var label: String { get }
}

// MARK: - Enums

enum TempUnit: String, CaseIterable, SettingOption {
    case system, celsius, fahrenheit
    var label: String {
        switch self {
        case .system:     return "Auto"
        case .celsius:    return "°C"
        case .fahrenheit: return "°F"
        }
    }
}

enum WindUnit: String, CaseIterable, SettingOption {
    case system, kmh, mph, ms
    var label: String {
        switch self {
        case .system: return "Auto"
        case .kmh:    return "km/h"
        case .mph:    return "mph"
        case .ms:     return "m/s"
        }
    }
}

enum WidgetPosition: String, CaseIterable, SettingOption {
    case topRight, topLeft, bottomRight, bottomLeft
    var label: String {
        switch self {
        case .topRight:    return "↗ TR"
        case .topLeft:     return "↖ TL"
        case .bottomRight: return "↘ BR"
        case .bottomLeft:  return "↙ BL"
        }
    }
    var fullLabel: String {
        switch self {
        case .topRight:    return "Top Right"
        case .topLeft:     return "Top Left"
        case .bottomRight: return "Bottom Right"
        case .bottomLeft:  return "Bottom Left"
        }
    }
}

enum GlassStyle: String, CaseIterable, SettingOption {
    case frosted, clear
    var label: String {
        switch self {
        case .frosted: return "Frosted"
        case .clear:   return "Clear"
        }
    }
}

enum RefreshInterval: String, CaseIterable, SettingOption {
    case five, fifteen, thirty, hour
    var label: String {
        switch self {
        case .five:    return "5 min"
        case .fifteen: return "15 min"
        case .thirty:  return "30 min"
        case .hour:    return "1 hr"
        }
    }
    var seconds: TimeInterval {
        switch self {
        case .five:    return 300
        case .fifteen: return 900
        case .thirty:  return 1800
        case .hour:    return 3600
        }
    }
}

// MARK: - Settings Store

class SettingsStore: ObservableObject {

    @Published var tempUnit: TempUnit {
        didSet { UserDefaults.standard.set(tempUnit.rawValue, forKey: Keys.tempUnit) }
    }
    @Published var windUnit: WindUnit {
        didSet { UserDefaults.standard.set(windUnit.rawValue, forKey: Keys.windUnit) }
    }
    @Published var position: WidgetPosition {
        didSet { UserDefaults.standard.set(position.rawValue, forKey: Keys.position) }
    }
    @Published var refreshInterval: RefreshInterval {
        didSet { UserDefaults.standard.set(refreshInterval.rawValue, forKey: Keys.refresh) }
    }
    @Published var glassStyle: GlassStyle {
        didSet { UserDefaults.standard.set(glassStyle.rawValue, forKey: Keys.glassStyle) }
    }

    private enum Keys {
        static let tempUnit   = "ww.tempUnit"
        static let windUnit   = "ww.windUnit"
        static let position   = "ww.position"
        static let refresh    = "ww.refresh"
        static let glassStyle = "ww.glassStyle"
    }

    init() {
        let ud = UserDefaults.standard
        tempUnit        = TempUnit(rawValue:       ud.string(forKey: Keys.tempUnit)   ?? "") ?? .system
        windUnit        = WindUnit(rawValue:        ud.string(forKey: Keys.windUnit)   ?? "") ?? .system
        position        = WidgetPosition(rawValue:  ud.string(forKey: Keys.position)   ?? "") ?? .topRight
        refreshInterval = RefreshInterval(rawValue: ud.string(forKey: Keys.refresh)    ?? "") ?? .fifteen
        glassStyle      = GlassStyle(rawValue:      ud.string(forKey: Keys.glassStyle) ?? "") ?? .frosted
    }
}

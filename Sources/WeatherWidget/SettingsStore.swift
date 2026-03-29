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
        switch self { case .system: return "Auto"; case .celsius: return "°C"; case .fahrenheit: return "°F" }
    }
}

enum WindUnit: String, CaseIterable, SettingOption {
    case system, kmh, mph, ms
    var label: String {
        switch self { case .system: return "Auto"; case .kmh: return "km/h"; case .mph: return "mph"; case .ms: return "m/s" }
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
}

enum RefreshInterval: String, CaseIterable, SettingOption {
    case five, fifteen, thirty, hour
    var label: String {
        switch self { case .five: return "5 min"; case .fifteen: return "15 min"; case .thirty: return "30 min"; case .hour: return "1 hr" }
    }
    var seconds: TimeInterval {
        switch self { case .five: return 300; case .fifteen: return 900; case .thirty: return 1800; case .hour: return 3600 }
    }
}

enum GlassIntensity: String, CaseIterable, SettingOption {
    case light, medium, heavy
    var label: String {
        switch self { case .light: return "Light"; case .medium: return "Medium"; case .heavy: return "Heavy" }
    }
    var blurRadius: CGFloat {
        switch self { case .light: return 4; case .medium: return 8; case .heavy: return 16 }
    }
    var overlayScale: Double {
        switch self { case .light: return 0.6; case .medium: return 1.0; case .heavy: return 1.5 }
    }
    var distortionScale: Float {
        switch self { case .light: return -0.25; case .medium: return -0.45; case .heavy: return -0.65 }
    }
}

// MARK: - Settings Store

class SettingsStore: ObservableObject {

    @Published var tempUnit: TempUnit {
        didSet { save(tempUnit.rawValue, forKey: Keys.tempUnit) }
    }
    @Published var windUnit: WindUnit {
        didSet { save(windUnit.rawValue, forKey: Keys.windUnit) }
    }
    @Published var position: WidgetPosition {
        didSet { save(position.rawValue, forKey: Keys.position) }
    }
    @Published var refreshInterval: RefreshInterval {
        didSet { save(refreshInterval.rawValue, forKey: Keys.refresh) }
    }
    @Published var glassIntensity: GlassIntensity {
        didSet { save(glassIntensity.rawValue, forKey: Keys.glass) }
    }

    private enum Keys {
        static let tempUnit = "ww.tempUnit"
        static let windUnit = "ww.windUnit"
        static let position = "ww.position"
        static let refresh  = "ww.refresh"
        static let glass    = "ww.glass"
    }

    init() {
        let ud = UserDefaults.standard
        tempUnit        = TempUnit(rawValue:         ud.string(forKey: Keys.tempUnit) ?? "") ?? .system
        windUnit        = WindUnit(rawValue:          ud.string(forKey: Keys.windUnit) ?? "") ?? .system
        position        = WidgetPosition(rawValue:    ud.string(forKey: Keys.position) ?? "") ?? .topRight
        refreshInterval = RefreshInterval(rawValue:   ud.string(forKey: Keys.refresh) ?? "") ?? .fifteen
        glassIntensity  = GlassIntensity(rawValue:    ud.string(forKey: Keys.glass)   ?? "") ?? .medium
    }

    private func save(_ value: String, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
}

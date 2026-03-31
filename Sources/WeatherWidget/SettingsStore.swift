import Foundation
import CoreGraphics
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

enum TimeFormat: String, CaseIterable, SettingOption {
    case auto, twelveHour, twentyFourHour
    var label: String {
        switch self {
        case .auto:           return "Auto"
        case .twelveHour:     return "12h"
        case .twentyFourHour: return "24h"
        }
    }
    var use24h: Bool {
        switch self {
        case .auto:
            let template = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current) ?? ""
            return template.contains("H") || template.contains("k")
        case .twelveHour:     return false
        case .twentyFourHour: return true
        }
    }
}

enum WidgetSize: String, CaseIterable, SettingOption {
    case compact, standard, large
    var label: String {
        switch self {
        case .compact:  return "S"
        case .standard: return "M"
        case .large:    return "L"
        }
    }
    var windowSize: CGSize {
        switch self {
        case .compact:  return CGSize(width: 280, height: 200)
        case .standard: return CGSize(width: 280, height: 380)
        case .large:    return CGSize(width: 280, height: 520)
        }
    }
}

enum LocationMode: String, CaseIterable, SettingOption {
    case auto, manual
    var label: String {
        switch self {
        case .auto:   return "Auto"
        case .manual: return "Custom"
        }
    }
}

// Info cells shown in the detail panel
enum DetailCell: String, CaseIterable, Identifiable, Hashable {
    case feelsLike, humidity, wind, uvIndex, rain, dewPoint
    var id: String { rawValue }
    var label: String {
        switch self {
        case .feelsLike: return "Feels Like"
        case .humidity:  return "Humidity"
        case .wind:      return "Wind"
        case .uvIndex:   return "UV Index"
        case .rain:      return "Rain"
        case .dewPoint:  return "Dew Point"
        }
    }
    var shortLabel: String {
        switch self {
        case .feelsLike: return "Feels Like"
        case .humidity:  return "Humidity"
        case .wind:      return "Wind"
        case .uvIndex:   return "UV Index"
        case .rain:      return "Rain"
        case .dewPoint:  return "Dew Pt"
        }
    }
    var icon: String {
        switch self {
        case .feelsLike: return "thermometer.medium"
        case .humidity:  return "humidity"
        case .wind:      return "wind"
        case .uvIndex:   return "sun.max.fill"
        case .rain:      return "cloud.rain"
        case .dewPoint:  return "thermometer.snowflake"
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
    @Published var timeFormat: TimeFormat {
        didSet { UserDefaults.standard.set(timeFormat.rawValue, forKey: Keys.timeFormat) }
    }
    @Published var widgetSize: WidgetSize {
        didSet { UserDefaults.standard.set(widgetSize.rawValue, forKey: Keys.widgetSize) }
    }
    @Published var visibleDetailCells: Set<DetailCell> {
        didSet {
            let str = visibleDetailCells.map(\.rawValue).joined(separator: ",")
            UserDefaults.standard.set(str, forKey: Keys.visibleDetailCells)
        }
    }
    @Published var frostedOpacity: Double {
        didSet { UserDefaults.standard.set(frostedOpacity, forKey: Keys.frostedOpacity) }
    }
    @Published var autoHideOnUnlock: Bool {
        didSet { UserDefaults.standard.set(autoHideOnUnlock, forKey: Keys.autoHideOnUnlock) }
    }
    @Published var targetScreenName: String {
        didSet { UserDefaults.standard.set(targetScreenName, forKey: Keys.targetScreenName) }
    }
    @Published var locationMode: LocationMode {
        didSet { UserDefaults.standard.set(locationMode.rawValue, forKey: Keys.locationMode) }
    }
    @Published var manualCityName: String {
        didSet { UserDefaults.standard.set(manualCityName, forKey: Keys.manualCityName) }
    }
    @Published var manualLatitude: Double {
        didSet { UserDefaults.standard.set(manualLatitude, forKey: Keys.manualLatitude) }
    }
    @Published var manualLongitude: Double {
        didSet { UserDefaults.standard.set(manualLongitude, forKey: Keys.manualLongitude) }
    }

    private enum Keys {
        static let tempUnit           = "ww.tempUnit"
        static let windUnit           = "ww.windUnit"
        static let position           = "ww.position"
        static let refresh            = "ww.refresh"
        static let glassStyle         = "ww.glassStyle"
        static let timeFormat         = "ww.timeFormat"
        static let widgetSize         = "ww.widgetSize"
        static let visibleDetailCells = "ww.visibleDetailCells"
        static let frostedOpacity     = "ww.frostedOpacity"
        static let autoHideOnUnlock   = "ww.autoHideOnUnlock"
        static let targetScreenName   = "ww.targetScreenName"
        static let locationMode       = "ww.locationMode"
        static let manualCityName     = "ww.manualCityName"
        static let manualLatitude     = "ww.manualLatitude"
        static let manualLongitude    = "ww.manualLongitude"
    }

    init() {
        let ud = UserDefaults.standard
        tempUnit        = TempUnit(rawValue:       ud.string(forKey: Keys.tempUnit)   ?? "") ?? .system
        windUnit        = WindUnit(rawValue:        ud.string(forKey: Keys.windUnit)   ?? "") ?? .system
        position        = WidgetPosition(rawValue:  ud.string(forKey: Keys.position)   ?? "") ?? .bottomLeft
        refreshInterval = RefreshInterval(rawValue: ud.string(forKey: Keys.refresh)    ?? "") ?? .fifteen
        glassStyle      = GlassStyle(rawValue:      ud.string(forKey: Keys.glassStyle) ?? "") ?? .clear
        timeFormat      = TimeFormat(rawValue:      ud.string(forKey: Keys.timeFormat) ?? "") ?? .auto
        widgetSize      = WidgetSize(rawValue:      ud.string(forKey: Keys.widgetSize) ?? "") ?? .standard
        frostedOpacity  = ud.object(forKey: Keys.frostedOpacity) != nil
                            ? ud.double(forKey: Keys.frostedOpacity) : 1.0
        autoHideOnUnlock = ud.object(forKey: Keys.autoHideOnUnlock) != nil
                            ? ud.bool(forKey: Keys.autoHideOnUnlock) : true
        targetScreenName = ud.string(forKey: Keys.targetScreenName) ?? ""
        locationMode    = LocationMode(rawValue: ud.string(forKey: Keys.locationMode) ?? "") ?? .auto
        manualCityName  = ud.string(forKey: Keys.manualCityName) ?? ""
        manualLatitude  = ud.double(forKey: Keys.manualLatitude)
        manualLongitude = ud.double(forKey: Keys.manualLongitude)

        if let str = ud.string(forKey: Keys.visibleDetailCells), !str.isEmpty {
            let cells = str.split(separator: ",").compactMap { DetailCell(rawValue: String($0)) }
            visibleDetailCells = Set(cells)
        } else {
            visibleDetailCells = Set(DetailCell.allCases)
        }
    }
}

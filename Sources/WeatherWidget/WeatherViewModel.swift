import Foundation
import AppKit
import Combine

// MARK: - Models

struct ForecastDay {
    let high: Double
    let low: Double
    let conditionCode: Int
    let dayLabel: String
}

struct WeatherData {
    let temperature: Double
    let feelsLike: Double
    let high: Double
    let low: Double
    let condition: String
    let conditionCode: Int
    let windSpeed: Double
    let humidity: Int
    let uvIndex: Double
    let precipChance: Int
    let dewPoint: Double
    let sunriseISO: String   // "2026-03-31T06:45" — format at display time
    let sunsetISO: String
    let forecast: [ForecastDay]
    let city: String
    let windUnit: String

    var tempString: String      { "\(Int(temperature.rounded()))°" }
    var feelsLikeString: String { "\(Int(feelsLike.rounded()))°" }
    var dewPointString: String  { "\(Int(dewPoint.rounded()))°" }
    var highLowString: String   { "H: \(Int(high.rounded()))° · L: \(Int(low.rounded()))°" }
    var windString: String      { "\(Int(windSpeed.rounded())) \(windUnit)" }
    var uvString: String        { "\(Int(uvIndex.rounded()))" }
    var precipString: String    { "\(precipChance)%" }
}

// MARK: - Sun time formatter (module-level so WeatherView can use it too)

func formatSunTime(_ iso: String, use24h: Bool) -> String {
    let parts = iso.split(separator: "T")
    guard parts.count == 2 else { return iso }
    let time = String(parts[1].prefix(5))
    let comps = time.split(separator: ":")
    guard comps.count == 2, let h = Int(comps[0]) else { return time }
    if use24h {
        return time
    } else {
        let ampm = h >= 12 ? "PM" : "AM"
        let h12  = h == 0 ? 12 : (h > 12 ? h - 12 : h)
        return "\(h12):\(comps[1]) \(ampm)"
    }
}

// MARK: - API Response Types

private struct GeoResponse: Codable {
    let city: String
    let latitude: Double
    let longitude: Double
}

private struct OpenMeteoResponse: Codable {
    let current: Current
    let daily: Daily

    struct Current: Codable {
        let temperature2m: Double
        let apparentTemperature: Double
        let weatherCode: Int
        let windSpeed10m: Double
        let relativeHumidity2m: Int
        let uvIndex: Double
        let dewPoint2m: Double

        enum CodingKeys: String, CodingKey {
            case temperature2m        = "temperature_2m"
            case apparentTemperature  = "apparent_temperature"
            case weatherCode          = "weather_code"
            case windSpeed10m         = "wind_speed_10m"
            case relativeHumidity2m   = "relative_humidity_2m"
            case uvIndex              = "uv_index"
            case dewPoint2m           = "dew_point_2m"
        }
    }

    struct Daily: Codable {
        let temperature2mMax: [Double]
        let temperature2mMin: [Double]
        let precipitationProbabilityMax: [Int]
        let weatherCode: [Int]
        let time: [String]
        let sunrise: [String]
        let sunset: [String]

        enum CodingKeys: String, CodingKey {
            case temperature2mMax            = "temperature_2m_max"
            case temperature2mMin            = "temperature_2m_min"
            case precipitationProbabilityMax = "precipitation_probability_max"
            case weatherCode                 = "weather_code"
            case time
            case sunrise
            case sunset
        }
    }
}

// MARK: - ViewModel

@MainActor
class WeatherViewModel: ObservableObject {
    @Published var weather: WeatherData?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let settings: SettingsStore
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?

    init(settings: SettingsStore) {
        self.settings = settings
        setupObservers()
        startRefreshTimer()
    }

    private func setupObservers() {
        // Re-fetch when unit or data source settings change
        settings.$tempUnit.dropFirst().map { _ in () }
            .merge(with: settings.$windUnit.dropFirst().map { _ in () })
            .merge(with: settings.$locationMode.dropFirst().map { _ in () })
            .merge(with: settings.$manualCityName.dropFirst().map { _ in () })
            .merge(with: settings.$widgetSize.dropFirst().map { _ in () })
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] in Task { await self?.fetch() } }
            .store(in: &cancellables)

        // Restart timer when interval changes
        settings.$refreshInterval
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.startRefreshTimer() }
            .store(in: &cancellables)
    }

    func startRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: settings.refreshInterval.seconds,
            repeats: true
        ) { [weak self] _ in Task { await self?.fetch() } }
    }

    // MARK: - Computed unit helpers

    var useFahrenheit: Bool {
        switch settings.tempUnit {
        case .system:
            if #available(macOS 13, *) { return Locale.current.measurementSystem == .us }
            return false
        case .celsius:    return false
        case .fahrenheit: return true
        }
    }

    private var windApiUnit: String {
        switch settings.windUnit {
        case .system: return useFahrenheit ? "mph" : "kmh"
        case .kmh:    return "kmh"
        case .mph:    return "mph"
        case .ms:     return "ms"
        }
    }

    private var windDisplayUnit: String {
        switch settings.windUnit {
        case .system: return useFahrenheit ? "mph" : "km/h"
        case .kmh:    return "km/h"
        case .mph:    return "mph"
        case .ms:     return "m/s"
        }
    }

    // MARK: - Fetch

    func fetch() async {
        isLoading = true
        errorMessage = nil
        let fahrenheit  = useFahrenheit
        let windApi     = windApiUnit
        let windDisplay = windDisplayUnit
        do {
            let geo  = try await fetchGeo()
            let data = try await fetchWeather(geo: geo, useFahrenheit: fahrenheit,
                                              windApiUnit: windApi, windDisplayUnit: windDisplay)
            self.weather = data
        } catch {
            errorMessage = "Could not load weather"
        }
        isLoading = false
    }

    private func fetchGeo() async throws -> GeoResponse {
        // Use manual location if configured
        if settings.locationMode == .manual, !settings.manualCityName.isEmpty {
            return GeoResponse(
                city: settings.manualCityName,
                latitude: settings.manualLatitude,
                longitude: settings.manualLongitude
            )
        }
        let url = URL(string: "https://ipapi.co/json/")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(GeoResponse.self, from: data)
    }

    private func fetchWeather(
        geo: GeoResponse,
        useFahrenheit: Bool,
        windApiUnit: String,
        windDisplayUnit: String
    ) async throws -> WeatherData {
        let tempUnit     = useFahrenheit ? "fahrenheit" : "celsius"
        let forecastDays = settings.widgetSize == .large ? 4 : 1

        var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        comps.queryItems = [
            .init(name: "latitude",          value: "\(geo.latitude)"),
            .init(name: "longitude",         value: "\(geo.longitude)"),
            .init(name: "current",           value: "temperature_2m,apparent_temperature,weather_code,wind_speed_10m,relative_humidity_2m,uv_index,dew_point_2m"),
            .init(name: "daily",             value: "temperature_2m_max,temperature_2m_min,precipitation_probability_max,weather_code,sunrise,sunset"),
            .init(name: "temperature_unit",  value: tempUnit),
            .init(name: "wind_speed_unit",   value: windApiUnit),
            .init(name: "timezone",          value: "auto"),
            .init(name: "forecast_days",     value: "\(forecastDays)"),
        ]

        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        let resp = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        let c = resp.current
        let d = resp.daily

        // Build optional 3-day forecast (indices 1-3, skipping today at index 0)
        var forecast: [ForecastDay] = []
        if settings.widgetSize == .large {
            for i in 1..<min(4, d.temperature2mMax.count) {
                forecast.append(ForecastDay(
                    high: d.temperature2mMax[i],
                    low:  d.temperature2mMin[i],
                    conditionCode: d.weatherCode.indices.contains(i) ? d.weatherCode[i] : 0,
                    dayLabel: dayLabel(from: d.time.indices.contains(i) ? d.time[i] : "")
                ))
            }
        }

        return WeatherData(
            temperature:  c.temperature2m,
            feelsLike:    c.apparentTemperature,
            high:         d.temperature2mMax.first ?? c.temperature2m,
            low:          d.temperature2mMin.first ?? c.temperature2m,
            condition:    Self.conditionLabel(for: c.weatherCode),
            conditionCode: c.weatherCode,
            windSpeed:    c.windSpeed10m,
            humidity:     c.relativeHumidity2m,
            uvIndex:      c.uvIndex,
            precipChance: d.precipitationProbabilityMax.first ?? 0,
            dewPoint:     c.dewPoint2m,
            sunriseISO:   d.sunrise.first ?? "",
            sunsetISO:    d.sunset.first  ?? "",
            forecast:     forecast,
            city:         geo.city,
            windUnit:     windDisplayUnit
        )
    }

    // MARK: - Helpers

    private func dayLabel(from dateStr: String) -> String {
        guard dateStr.count >= 10 else { return dateStr }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        guard let date = df.date(from: String(dateStr.prefix(10))) else { return dateStr }
        if Calendar.current.isDateInTomorrow(date) { return "Tomorrow" }
        let wf = DateFormatter()
        wf.dateFormat = "EEE"
        return wf.string(from: date)
    }

    // MARK: - WMO Code Helpers

    static func conditionLabel(for code: Int) -> String {
        switch code {
        case 0:        return "Clear Sky"
        case 1:        return "Mainly Clear"
        case 2:        return "Partly Cloudy"
        case 3:        return "Overcast"
        case 45, 48:   return "Foggy"
        case 51, 53:   return "Light Drizzle"
        case 55:       return "Heavy Drizzle"
        case 56, 57:   return "Freezing Drizzle"
        case 61, 63:   return "Rain"
        case 65:       return "Heavy Rain"
        case 66, 67:   return "Freezing Rain"
        case 71, 73:   return "Snowfall"
        case 75:       return "Heavy Snow"
        case 77:       return "Snow Grains"
        case 80, 81:   return "Rain Showers"
        case 82:       return "Heavy Showers"
        case 85, 86:   return "Snow Showers"
        case 95:       return "Thunderstorm"
        case 96, 99:   return "Thunderstorm & Hail"
        default:       return "Unknown"
        }
    }

    static func sfSymbol(for code: Int) -> String {
        switch code {
        case 0, 1:     return "sun.max.fill"
        case 2:        return "cloud.sun.fill"
        case 3:        return "cloud.fill"
        case 45, 48:   return "cloud.fog.fill"
        case 51...57:  return "cloud.drizzle.fill"
        case 61...67:  return "cloud.rain.fill"
        case 71...77:  return "cloud.snow.fill"
        case 80...82:  return "cloud.heavyrain.fill"
        case 85, 86:   return "cloud.snow.fill"
        case 95:       return "cloud.bolt.fill"
        case 96, 99:   return "cloud.bolt.rain.fill"
        default:       return "cloud.fill"
        }
    }
}

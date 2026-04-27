import Foundation

struct CachedWeather: Codable {
    let data: WeatherData
    let geoKey: String      // "lat2dp,lon2dp" — changes on location switch to invalidate
    let fetchedAt: Date
}

actor WeatherCache {
    static let shared = WeatherCache()

    private var cacheURL: URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = caches.appendingPathComponent("com.apple.weatherwidget", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("weather-cache.json")
    }

    func load(for geoKey: String) -> CachedWeather? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        guard let cached = try? JSONDecoder().decode(CachedWeather.self, from: data) else {
            try? FileManager.default.removeItem(at: cacheURL)
            return nil
        }
        guard cached.geoKey == geoKey else { return nil }
        return cached
    }

    func save(_ weather: WeatherData, geoKey: String) {
        let cached = CachedWeather(data: weather, geoKey: geoKey, fetchedAt: Date())
        guard let data = try? JSONEncoder().encode(cached) else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }

    static func geoKey(latitude: Double, longitude: Double) -> String {
        let lat = (latitude  * 100).rounded() / 100
        let lon = (longitude * 100).rounded() / 100
        return "\(lat),\(lon)"
    }
}

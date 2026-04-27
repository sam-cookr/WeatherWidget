import XCTest
@testable import WeatherWidget

final class WeatherCacheTests: XCTestCase {
    private let testGeoKey = "37.77,-122.42"

    private func sampleWeather() -> WeatherData {
        WeatherData(
            temperature: 18, feelsLike: 16, high: 21, low: 14,
            condition: "Partly Cloudy", conditionCode: 2,
            windSpeed: 12, humidity: 70, uvIndex: 3,
            precipChance: 10, dewPoint: 12,
            sunriseISO: "2026-04-23T06:30", sunsetISO: "2026-04-23T19:45",
            forecast: [], city: "San Francisco", windUnit: "km/h"
        )
    }

    func testRoundTrip() async throws {
        let cache = WeatherCache()
        let weather = sampleWeather()
        await cache.save(weather, geoKey: testGeoKey)
        let loaded = await cache.load(for: testGeoKey)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.data.city, "San Francisco")
        XCTAssertEqual(loaded?.geoKey, testGeoKey)
    }

    func testGeoKeyMismatchReturnsNil() async throws {
        let cache = WeatherCache()
        let weather = sampleWeather()
        await cache.save(weather, geoKey: testGeoKey)
        let loaded = await cache.load(for: "0.0,0.0")
        XCTAssertNil(loaded)
    }

    func testGeoKeyRounding() {
        let key = WeatherCache.geoKey(latitude: 37.7749, longitude: -122.4194)
        XCTAssertEqual(key, "37.77,-122.42")
    }
}

// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WeatherWidget",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/Lakr233/SkyLightWindow", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "WeatherWidget",
            dependencies: ["SkyLightWindow"],
            path: "Sources/WeatherWidget"
        )
    ]
)

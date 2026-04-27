// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WeatherWidget",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/Lakr233/SkyLightWindow", from: "1.0.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.9.1"),
    ],
    targets: [
        .target(
            name: "WidgetScreenCore",
            path: "Sources/WidgetScreenCore"
        ),
        .target(
            name: "WidgetScreenWindowing",
            dependencies: [
                "WidgetScreenCore",
                .product(name: "SkyLightWindow", package: "SkyLightWindow"),
            ],
            path: "Sources/WidgetScreenWindowing"
        ),
        .executableTarget(
            name: "WeatherWidget",
            dependencies: [
                "WidgetScreenWindowing",
                "WidgetScreenCore",
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Sources/WeatherWidget"
        ),
        .testTarget(
            name: "WeatherWidgetTests",
            dependencies: ["WeatherWidget"],
            path: "Tests/WeatherWidgetTests"
        ),
        .testTarget(
            name: "WidgetScreenCoreTests",
            dependencies: ["WidgetScreenCore"],
            path: "Tests/WidgetScreenCoreTests"
        ),
        .testTarget(
            name: "WidgetScreenWindowingTests",
            dependencies: ["WidgetScreenWindowing"],
            path: "Tests/WidgetScreenWindowingTests"
        ),
    ]
)

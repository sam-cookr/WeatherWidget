# WeatherWidget

A minimal macOS weather widget with a native glass aesthetic. It floats in the corner of your screen and stays visible **above the lock screen** ![IMG_3147](https://github.com/user-attachments/assets/a58f3118-fc3f-45de-8e32-ce93235c6f12)
— no wallpaper access, no Screen Recording permission required.

![macOS 15+](https://img.shields.io/badge/macOS-15%2B-blue) ![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange) ![License MIT](https://img.shields.io/badge/license-MIT-green)

## Download

Grab the latest **WeatherWidget.dmg** from the [Releases](https://github.com/sam-cookr/WeatherWidget/releases/latest) page.

1. Open the DMG
2. Drag **WeatherWidget** into Applications
3. Launch it — the widget appears in the top-right corner
4. Lock your screen to see it on the lock screen

> **Gatekeeper note** — the app is ad-hoc signed (no Apple Developer account). On first launch, right-click → **Open**, then Settings -> Privacy & Security -> Open anyway


## Features

- **Native glass** — uses `NSGlassEffectView` (the same compositor glass Apple uses for the lock screen) so it blends naturally with any wallpaper
- **Lock screen** — sits above the lock screen and screensaver via SkyLight private APIs; no Screen Recording permission needed
- **Live weather** — temperature, feels-like, high/low, humidity, wind, UV index, precipitation probability, dew point, sunrise & sunset
- **Auto-refresh** — configurable interval (5 min → 1 hour)
- **Settings panel** — slide-in panel for all options; position changes take effect immediately

## Settings

Click the ⚙ gear icon in the widget header to open settings.

| Setting | Options |
|---|---|
| Temperature | Auto (system locale) / °C / °F |
| Wind speed | Auto / km/h / mph / m/s |
| Position | Top-right / top-left / bottom-right / bottom-left |
| Auto-refresh | 5 min / 15 min / 30 min / 1 hr |

## Data Sources

Both APIs are free with no account or API key required.

- **Location** — [ipapi.co](https://ipapi.co) — IP-based city lookup; no GPS coordinates used or stored
- **Weather** — [Open-Meteo](https://open-meteo.com) — open-source weather API

## Building from Source

Requires Xcode 15+ and macOS 15 (Sequoia).

```bash
# Run directly (development)
swift build
.build/debug/WeatherWidget

# Build a release .app + .dmg
chmod +x build_app.sh
./build_app.sh
```

Or open in Xcode:

```bash
open Package.swift
```

## How It Works

The widget uses `SkyLightWindow` plus direct SkyLight private API calls (`SLSSpaceCreate`, `SLSSpaceSetAbsoluteLevel`) to place the window in a compositor space at level 300 — the same level as the macOS lock screen UI. `NSGlassEffectView` (a private AppKit class available in macOS 15+) provides the native frosted-glass blur without needing the Screen Recording entitlement.

## Dependencies

- [SkyLightWindow](https://github.com/Lakr233/SkyLightWindow) — window placement above the lock screen

## License

MIT

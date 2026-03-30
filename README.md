# WeatherWidget

A minimal macOS weather widget with a native glass aesthetic. It floats in the corner of your screen and stays visible **above the lock screen** — no wallpaper access, no Screen Recording permission required.

<img src="https://github.com/user-attachments/assets/8d510c22-bdf4-48f3-bdd8-ae7b34d8c839" width="300" />


![macOS 15+](https://img.shields.io/badge/macOS-15%2B-blue) ![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange) ![License MIT](https://img.shields.io/badge/license-MIT-green)

## Download

Grab the latest **WeatherWidget.dmg** from the [Releases](https://github.com/sam-cookr/WeatherWidget/releases/latest) page.

1. Open the DMG
2. Drag **WeatherWidget** into Applications
3. Launch it — a first-run wizard walks you through position and unit preferences
4. Lock your screen (`Ctrl + Cmd + Q`) to see the widget above the lock screen

> **Gatekeeper note** — the app is notarized with a Developer ID. macOS should open it without warnings. If you see a Gatekeeper prompt anyway, go to **System Settings → Privacy & Security → Open Anyway**.

## Features

- **Lock screen visible** — sits above the lock screen and screensaver via SkyLight private APIs; no Screen Recording permission needed
- **Native glass** — uses `NSGlassEffectView` (the same compositor glass Apple uses for the lock screen); choose Frosted or Clear style
- **Live weather** — temperature, feels-like, high/low, humidity, wind, UV index, precipitation probability, dew point, sunrise & sunset
- **Auto-refresh** — configurable interval (5 min → 1 hour)
- **Menu bar toggle** — show or hide the widget on the desktop any time from the menu bar (`⌘W`)
- **Settings on lock screen** — tap the ⚙ gear icon on the widget while locked to change settings without unlocking

## Usage

WeatherWidget lives in the menu bar (☁ icon). It has no Dock icon.

| Action | How |
|---|---|
| Show / hide widget on desktop | Menu bar → **Show Widget** (`⌘W`) |
| Open full settings | Menu bar → **Settings…** (`⌘,`) |
| Change settings while locked | Tap the ⚙ gear icon on the widget |
| Quit | Menu bar → **Quit WeatherWidget** |

## Settings

| Setting | Options |
|---|---|
| Temperature | Auto (system locale) / °C / °F |
| Wind speed | Auto / km/h / mph / m/s |
| Position | Top-right / top-left / bottom-right / bottom-left |
| Glass style | Frosted / Clear |
| Auto-refresh | 5 min / 15 min / 30 min / 1 hr |

Settings are available both via the slide-in panel on the widget itself (works on the lock screen) and in the full preferences window from the menu bar.

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

The widget uses direct SkyLight private API calls (`SLSSpaceCreate`, `SLSSpaceSetAbsoluteLevel`) to place the window in a compositor space at level 300 — the same level as the macOS lock screen UI. `NSGlassEffectView` (a private AppKit class, macOS 15+) provides the native frosted-glass blur without needing the Screen Recording entitlement. On macOS versions where either API is unavailable, the app falls back gracefully to the [SkyLightWindow](https://github.com/Lakr233/SkyLightWindow) Swift package and `NSVisualEffectView`.

## FAQ

**The widget doesn't appear on my lock screen.**
Make sure you launched the app before locking. The widget auto-hides when you unlock; use **Show Widget** from the menu bar to bring it back on the desktop.

**My city is wrong.**
Location is detected by IP address (city-level), not GPS. VPNs will affect it.

**Can I set a custom location?**
Not currently — Open-Meteo coordinates come from the IP lookup.

**The app is blocked by Gatekeeper.**
Go to System Settings → Privacy & Security → Open Anyway. This is rare with a notarized build but can happen if macOS cached an older quarantine flag.

## Dependencies

- [SkyLightWindow](https://github.com/Lakr233/SkyLightWindow) — fallback window placement above the lock screen

## License

MIT

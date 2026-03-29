# WeatherWidget

A floating macOS weather widget with a liquid glass aesthetic. Sits in the corner of your desktop, stays visible on the lock screen and screensaver, and updates automatically.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue) ![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange) ![License MIT](https://img.shields.io/badge/license-MIT-green)

## Features

- **Liquid glass look** — multi-layer glass effect with refraction, chromatic aberration, caustic glow, specular highlights, and an angular-gradient border that traces the edge of the glass
- **Live wallpaper integration** — samples and distorts your actual desktop wallpaper through the glass using Core Image (Gaussian blur, barrel distortion, magnification, colour boost)
- **Lock screen & screensaver** — visible above the lock screen via [SkyLightWindow](https://github.com/Lakr233/SkyLightWindow)
- **Current conditions** — temperature, feels-like, high/low, humidity, wind, UV index, precipitation probability, dew point, sunrise & sunset
- **Auto-refresh** — configurable interval (5 min → 1 hour)
- **Settings panel** — slide-in glass panel for all customisation options

## Settings

| Setting | Options |
|---------|---------|
| Temperature | Auto (system locale) / °C / °F |
| Wind speed | Auto / km/h / mph / m/s |
| Widget position | Top-right / top-left / bottom-right / bottom-left |
| Glass depth | Light / Medium / Heavy |
| Auto-refresh | 5 min / 15 min / 30 min / 1 hr |

Open settings by clicking the ⚙ gear icon in the widget header.

## Data Sources

- **Location** — [ipapi.co](https://ipapi.co) (IP-based, no API key needed)
- **Weather** — [Open-Meteo](https://open-meteo.com) (free, no API key needed)

## Building

Requires Xcode 15+ and macOS 13+.

### Create a macOS App Bundle

To create a double-clickable `.app` bundle that can be moved to `/Applications`:

```bash
./build_app.sh
```

This will create `WeatherWidget.app` in the current directory. You can then move it to your `/Applications` folder.

### Running from Terminal (Development)

```bash
swift build -c release
.build/release/WeatherWidget
```

Or open in Xcode:

```bash
open Package.swift
```

## Dependencies

- [SkyLightWindow](https://github.com/Lakr233/SkyLightWindow) — renders the window above the lock screen and screensaver

## Permissions

On first launch macOS may ask for **Location** permission — this is used only for the IP-based city lookup and no coordinates are stored locally. The app does not collect or transmit any personal data.

## License

MIT

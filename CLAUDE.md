# WeatherWidget — Developer Notes for Claude

## What this app is

A macOS menu bar / lock-screen utility. A floating glass widget sits in a corner of the screen and displays live weather conditions. The key trick: it remains **visible above the macOS lock screen** without requiring Screen Recording permission, by using private SkyLight compositor APIs to place its window at level 300 (the lock-screen compositor layer).

The app has no Dock icon. Entry points are the menu bar status item (desktop) and the gear icon on the widget itself (lock screen).

---

## Architecture — one process, three window types

```
AppDelegate (NSObject, NSApplicationDelegate)
├── floatingWindow       — the glass widget (lock-screen visible, SkyLight space)
├── preferencesWindow    — NavigationSplitView settings (desktop only)
└── onboardingWindow     — first-launch wizard (desktop only)
```

`SettingsStore` is a single `ObservableObject` shared across all three windows via `.environmentObject(settings)`. Changes publish immediately via Combine; `AppDelegate.observeSettings()` subscribes to `settings.$position` to reposition the floating window in real time.

---

## Key files

| File | Role |
|---|---|
| `main.swift` | Entry point — creates `AppDelegate`, runs the app |
| `AppDelegate.swift` | Window lifecycle, menu bar icon, SkyLight placement, screen-lock observers |
| `WeatherView.swift` | Glass widget UI — `LockScreenGlassView` + weather content |
| `SettingsView.swift` | Slide-in settings panel **inside** the widget (for lock-screen use) |
| `PreferencesView.swift` | Full `NavigationSplitView` preferences window (desktop, via menu bar) |
| `OnboardingView.swift` | 3-step first-launch wizard |
| `WeatherViewModel.swift` | Async weather + geo fetch, unit conversion, WMO code mapping |
| `SettingsStore.swift` | `UserDefaults`-backed `@Published` settings; enums for all options |

---

## The SkyLight trick

`AppDelegate.delegateWindowToSkySpace(_:)` dynamically loads the private `SkyLight.framework` and calls:

1. `SLSMainConnectionID()` — get the compositor connection
2. `SLSSpaceCreate(conn, 1, 0)` — create a new compositor space
3. `SLSSpaceSetAbsoluteLevel(conn, space, 300)` — lock-screen level
4. `SLSShowSpaces(conn, [space])` — make it visible
5. `SLSSpaceAddWindowsAndRemoveFromSpaces(conn, space, [windowNumber], 7)` — move window into it

If any symbol is missing (future macOS), the code falls back to the `SkyLightWindow` Swift package (`SkyLightOperator.shared.delegateWindow`).

The window also sets `canBecomeVisibleWithoutLogin = true` and `window.level = Int32.max - 2`.

---

## Glass effect

`LockScreenGlassView` (in `WeatherView.swift`) wraps `NSGlassEffectView` — a private AppKit class available on macOS 15+ that provides the same compositor-level blur Apple uses for the lock screen itself. Falls back to `NSVisualEffectView(.hudWindow)` on older systems.

The background is: `LockScreenGlassView` + `Color.black.opacity(0.22)` dark overlay + a subtle top specular gradient. This keeps text readable on any wallpaper without sampling the wallpaper.

---

## Settings system

`SettingsStore` (`ObservableObject`) holds all user preferences as `@Published` properties backed by `UserDefaults` via `didSet`. No Combine pipeline needed for persistence — the `didSet` writes directly.

Position changes flow: `SettingsStore.$position` → `AppDelegate.observeSettings()` subscription → `repositionWindow(to:)` → `window.setFrameOrigin(...)` directly (no animation — SkyLight windows don't respond reliably to `NSAnimationContext`).

`SMAppService.mainApp` handles Launch at Login (macOS 13+). The toggle in `GeneralPane` calls `.register()` / `.unregister()` and reverts on failure.

---

## Weather data

Two unauthenticated APIs, no keys required:

- **Geo**: `https://ipapi.co/json/` → city, lat, lon (IP-based, ~city-level accuracy)
- **Weather**: `https://api.open-meteo.com/v1/forecast` → current conditions + daily summary

`WeatherViewModel.fetch()` is `async`, called on launch and on a repeating `Timer` (configurable interval). Unit conversion (°C/°F, km/h/mph/m/s) is applied at the API request level — Open-Meteo returns data in the requested unit directly.

---

## Onboarding

`UserDefaults.standard.bool(forKey: "ww.onboardingComplete")` gates first-launch. Set to `true` when the user taps "Get Started" in `OnboardingView`. To re-trigger onboarding during development:

```bash
defaults delete com.samcooke.WeatherWidget ww.onboardingComplete
```

---

## Building

```bash
# Debug run
swift build && .build/debug/WeatherWidget

# Release .app + .dmg (also generates icon and DMG background via Swift scripts)
./build_app.sh
```

`build_app.sh` calls `generate_icon.swift` and `generate_dmg_background.swift` (both pure AppKit/CoreGraphics, no dependencies), then ad-hoc codesigns the bundle with `codesign --force --deep --sign -`, creates a styled HFS+ DMG via `hdiutil` + AppleScript Finder view options, and converts to compressed UDZO.

---

## What NOT to change without careful thought

- **`window.level`** and **`delegateWindowToSkySpace`** — the SkyLight APIs are private and undocumented; small changes can break lock-screen visibility entirely or cause the window to appear on the wrong layer.
- **`canBecomeVisibleWithoutLogin = true`** — required for the window to exist before login.
- **`NSApp.setActivationPolicy(.accessory)`** — changing to `.regular` adds a Dock icon and changes app lifecycle behaviour. `.prohibited` removes the status item capability.
- **`isReleasedWhenClosed = false`** on all windows — the floating window must survive `orderOut`.

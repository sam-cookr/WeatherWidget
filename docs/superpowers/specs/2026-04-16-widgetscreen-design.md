# WidgetScreen — Design Spec

**Date:** 2026-04-16
**Status:** Draft for review
**Predecessor:** WeatherWidget v1.9

---

## 1. Identity & Scope

**WidgetScreen** is a curated macOS widget suite that floats above the lock screen and desktop using native liquid glass. It is pitched as *"macOS finally gets lock screen widgets."*

It is a **new project in a new repository**, not a fork. The existing `WeatherWidget` codebase remains as v1.9 for current users. Usable code (SkyLight window placement, glass view, weather data provider, IP geolocation) is **lifted and refactored**, not inherited.

### Differentiators

- Multiple independently-positioned widgets on the lock screen (Alcove is notch-centric; no other Mac app does this).
- Snap-to-grid positioning anywhere on screen, not preset corners.
- Broad widget set (not just weather or notch HUDs).
- Native liquid-glass aesthetic via `NSGlassEffectView` (macOS 15+) with graceful fallback.

### Non-goals (v1)

- No plugin / third-party widget API.
- No iCloud sync of layouts or settings.
- No Shortcuts / Automator integration.
- No localisation beyond English.
- No App Store distribution (private APIs in use — notarized DMG only).

### Widget Set — Phased

- **v1.0 launch suite (6):** Weather, Battery, Clock, Now Playing, Calendar, System
- **v1.1 (2):** Stocks, Countdown
- **v1.2 (2):** Photo, Focus

Each milestone is independently useful and shippable.

---

## 2. Architecture

### 2.1 Swift Package Structure

Four SPM targets within one repository:

- **`WidgetScreenCore`** — protocols, stores, theme, grid math, shared UI primitives (glass view, tile chrome). No widget-specific code. Smallest possible dependency surface.
- **`WidgetScreenWindowing`** — SkyLight/NSWindow management, multi-screen handling, edit mode overlay. Depends on Core.
- **`WidgetScreenWidgets`** — all launch widgets, each in its own subdirectory. Depends on Core.
- **`WidgetScreen`** (app target) — AppDelegate, menu bar, settings window, onboarding, glue. Depends on all of the above.

### 2.2 The `Widget` Protocol

The core abstraction. Each widget type conforms:

```swift
protocol Widget {
    static var id: String { get }                      // stable, e.g. "weather"
    static var displayName: String { get }
    static var iconSymbol: String { get }              // SF Symbol
    static var supportedSizes: [WidgetSize] { get }    // subset of [.small, .medium, .large]

    associatedtype ContentView: View
    associatedtype SettingsView: View
    associatedtype Provider: ObservableObject

    static func makeProvider() -> Provider
    static func makeView(size: WidgetSize, provider: Provider) -> ContentView
    static func makeSettingsView(provider: Provider) -> SettingsView
}
```

A new widget is one file in `Sources/WidgetScreenWidgets/<Name>/`:
- `<Name>Widget.swift` — conformance + view.
- `<Name>Provider.swift` — `ObservableObject` that fetches data.
- `<Name>SettingsView.swift` — per-widget settings pane.

Adding a widget touches no other file.

### 2.3 Window Model

One `NSWindow` per widget instance. Each window:
- Hosts a SwiftUI view rendered inside `NSGlassEffectView` (or `NSVisualEffectView` fallback).
- Is placed on a SkyLight space at compositor level 300 (same mechanism as WeatherWidget v1.9).
- Is independently draggable, resizable (snap-to-grid), and togglable.

A `WindowManager` singleton owns the window lifecycle — creating, repositioning, destroying windows as `LayoutStore` state changes.

### 2.4 Stores

Three ObservableObjects at the app level:

- **`AppSettings`** — theme, accent, typography, glass, density, corner radius, refresh defaults, units, permissions cache. Persisted in UserDefaults.
- **`LayoutStore`** — widget instances: `[WidgetInstance]` where each is `{ id: UUID, typeID: String, size: WidgetSize, gridOrigin: GridPoint, targetScreen: String? }`. Persisted as JSON in UserDefaults with a backup to `~/Library/Application Support/WidgetScreen/layout.json`.
- **`PermissionsStore`** — tracks permission state per widget; handles requests.

Per-widget settings live **inside each widget's Provider**, written to namespaced UserDefaults keys (e.g. `ws.widget.weather.locationMode`).

### 2.5 Grid & Positioning

- Default cell size: **40pt** (configurable in `AppSettings.density`: compact 32pt / standard 40pt / airy 48pt).
- Widget sizes: **small** (2×2 cells), **medium** (4×2), **large** (4×4). Some widgets (e.g. Clock) support multiple sizes.
- Grid positions stored as `GridPoint { col: Int, row: Int }` — device-independent.
- Collision detection: no two widget instances may occupy overlapping grid cells. Attempted drag to a colliding position snaps back or displaces with a visual indicator.

### 2.6 Edit Mode

A global `AppState.isEditing: Bool`. When true:
- A translucent grid overlay renders across the target screen at compositor level 299 (one below widgets, above wallpaper).
- Widgets show a subtle outline glow and drag handles.
- Clicking a widget opens a popover: size selector, accent override, remove button.
- Clicking an empty cell opens the "Add widget" gallery.
- Triggered via menu bar → "Edit layout" or `⌘E`.

---

## 3. Customization (Rich tier)

### 3.1 Global Settings

Organised into sections accessible from a left sidebar in the settings window:

**Appearance**
- Theme: light / dark / auto
- Accent colour: 8-colour palette + "match wallpaper" (sampled from current desktop image)
- Glass style: frosted / clear
- Glass blur intensity: slider, 0–100
- Glass opacity: slider, 30–100
- Corner radius: slider, 8–20pt
- Edit-mode tint: subtle / visible / off

**Typography**
- Family: SF Pro / SF Pro Rounded / SF Mono / New York
- Weight: light / regular / medium
- Numeric style: proportional / monospaced (affects clock and numeric widgets)

**Density**
- Compact / standard / airy — controls internal tile padding and grid cell size.

**Units**
- Temperature: auto / °C / °F
- Wind speed: auto / km/h / mph / m/s
- Time format: auto / 12h / 24h
- Date format: localized / ISO / custom

**Refresh**
- Default interval: 5 / 15 / 30 / 60 min
- Per-widget overrides available.

**Behaviour**
- Show on: lock screen / desktop / both (global, per-widget overrides possible in v1.1)
- Auto-hide on unlock: on/off
- Start at login: on/off
- Menu bar icon: on/off
- Target screen per widget (multi-monitor)

### 3.2 Per-Widget Settings

Each widget's settings pane, accessed via the sidebar "Widgets" expansion:

- Show / hide
- Size (mapped to supported sizes for that widget)
- Position (grid slot, can be nudged from here or set via edit mode)
- Accent override: use global / custom colour
- Content toggles specific to the widget:
  - **Weather:** Feels like / humidity / UV / rain / dew point / sunrise+sunset
  - **Battery:** Include peripherals / show percentage / show time remaining
  - **Clock:** Additional timezones, seconds on/off, world-clock mode
  - **Now Playing:** Music / Spotify / both, show album art, show scrub bar
  - **Calendar:** Which calendars, privacy tier (see §4.3)
  - **System:** Which stats (CPU / RAM / disk / network) and layout
- Widget-specific config (e.g. Weather manual location, Countdown target date, Clock timezones).

### 3.3 Settings UI Aesthetic

Visual reference: Alcove (`tryalcove.com`). Restrained, typographic, spacious, confident.

- Large left-aligned section titles. SF Pro, heavy weight, generous line height.
- Soft neutral background, no chrome, no box outlines. Space and type carry the structure.
- Rows: faint separator, SF Symbol icon on the left (coloured to subject), label, control on the right.
- Controls:
  - Segmented pickers for 2–3 way choices.
  - Sliders with live numeric readout.
  - Coloured-chip pickers for accent colour.
  - Live toggles, not "Apply" buttons.
- **Live preview pane** on the right: a miniature lock screen rendering with the user's current theme and layout. All changes reflect instantly.
- Sidebar navigation: Appearance · Typography · Density · Units · Refresh · Behaviour · Widgets · Permissions · About.

### 3.4 Onboarding

Four steps, each a full-window page with the live preview visible:

1. **Welcome** — explains what WidgetScreen does; "Grant access" button if any permissions are needed upfront.
2. **Pick widgets** — gallery of v1.0 widgets, click to include. Default: all enabled.
3. **Choose theme** — accent colour picker with live preview + light/dark toggle.
4. **Arrange layout** — opens the first edit-mode session with default layout pre-filled; "Done" finalises.

Post-onboarding: menu bar icon appears, widgets are live, lock screen shows them.

---

## 4. Data Sources, Permissions, Privacy

### 4.1 Data Sources Table

| Widget | Source | Permission | Refresh default |
|---|---|---|---|
| Weather | Open-Meteo API + ipwho.is for IP geolocation | None | 15 min |
| Battery | IOKit (`IOPowerSources`), IOBluetoothDevice | None | 1 min |
| Clock | System clock + timezone database | None | 1 s (display tick) |
| Now Playing | `MediaRemote.framework` (private) | None at runtime | Event-driven |
| Calendar | EventKit | Calendar access | 5 min |
| System | `host_statistics64`, `statfs`, `getifaddrs` | None | 10 s |
| Stocks (v1.1) | Yahoo Finance or Finnhub free tier (TBD in v1.1 spike) | None | 15 min |
| Countdown (v1.1) | User-entered dates | None | 1 h |
| Photo (v1.2) | User-chosen folder | Full Disk / folder access | Rotation only |
| Focus (v1.2) | `NSDistributedNotificationCenter` + DoNotDisturb plist (research required) | Possibly Accessibility or file read | Event-driven |

### 4.2 Private API Acceptance

WidgetScreen uses private APIs (SkyLight for lock-screen placement, MediaRemote for Now Playing). Distribution is notarized DMG via Developer ID, not App Store. This is the same model as WeatherWidget v1.9 and is accepted.

Each private-API call site is wrapped in a capability check and falls back gracefully if the symbol is unavailable. On macOS versions where Now Playing or lock-screen placement is unavailable, the widget or feature disables itself with a one-time user notification.

### 4.3 Calendar Privacy Tiers

Calendar is the only widget with inherently sensitive content. Three tiers, user-selectable per calendar source:

1. **Private (default)** — "Busy" placeholder + time + colour bar. Never shows event title.
2. **Title on desktop, hidden on lock** — detects `CGSessionCopyCurrentDictionary()["CGSSessionScreenIsLocked"]` and obfuscates accordingly.
3. **Always show title** — explicit opt-in.

### 4.4 Network Layer

Single `NetworkClient`:
- Shared `URLSession` with 10s timeout, disabled cookies, custom User-Agent.
- Per-endpoint response cache (last good payload + timestamp).
- Exponential backoff on failure: 1s, 5s, 30s, 2m, 10m, then hold at 10m.
- Network reachability monitoring — immediate retry on reconnect.
- Widgets display a subtle staleness dot if data is older than 30 minutes.

### 4.5 Permissions Pane

A settings section listing each widget's required permissions, current state (granted / denied / not yet asked), and a one-click button to request or open System Settings deeplinks. Avoids surprising mid-use prompts.

---

## 5. Error Handling, Edge Cases, Testing

### 5.1 Failure Philosophy

A widget never crashes the app or disappears unannounced. Failure modes:

- **Stale data:** faded last-known value + small "⋯" indicator.
- **No cached value:** single-line "Couldn't update" with retry affordance on tap.
- **Permission denied:** inline CTA "Grant Calendar access →" that deep-links into System Settings.
- **Private API unavailable:** widget disables itself; user sees a one-time banner.
- **Invalid user config:** caught at save time in the settings pane, never at runtime.

### 5.2 Multi-Screen

- Monitor unplugged: widgets migrate to primary screen, grid origins preserved where they fit, clipped where they don't. Menu bar notice summarises the move.
- Resolution change: `LayoutStore.revalidate()` called on `NSScreen.didChange` notifications.
- Multiple screens connected: each widget's `targetScreen` identifier determines placement; unknown IDs fall back to primary.

### 5.3 Lock / Unlock / Sleep / Wake

- Lock: all configured widgets render at compositor level 300 above lock UI.
- Unlock: respect `AppSettings.autoHideOnUnlock` (default true; hides widgets on desktop).
- Sleep: widgets pause refresh immediately.
- Wake: 5s grace period, then one synchronised refresh to avoid thundering the network.

### 5.4 Stage Manager / Mission Control / Spaces

Widgets at compositor level 300 are above these system UIs on the lock screen. On the desktop with these modes active, widgets should hide or fade — to be verified during development; add to QA checklist.

### 5.5 Testing

**Unit tests (`WidgetScreenCoreTests`):**
- Grid math: snap-to-cell rounding, collision detection, free-cell finding.
- `LayoutStore` JSON round-trip.
- Theme resolution: accent colour → derived palette (shadow, border, text).
- Unit conversions: all combinations, edge values (negative temps, zero wind).

**Widget tests (`WidgetScreenWidgetsTests`):**
- Each provider tested against a mock `NetworkClient` with golden JSON fixtures.
- SwiftUI snapshot tests: every widget × every supported size × light/dark theme.

**Integration tests (manual QA checklist at `docs/qa-checklist.md`):**
- Fresh install → onboarding → first widget visible on lock screen.
- Add / remove widgets, drag, snap.
- Multi-monitor: connect, disconnect, resolution change.
- Each permission flow: grant / deny / revoke / re-grant.
- Sleep / wake / lock / unlock behaviours.
- Private API absence (simulated via feature flag).

**Widget gallery debug harness:** a hidden menu item opens a window rendering every widget at every size in both themes simultaneously. Catches visual regressions in one glance.

---

## 6. Migration & Rollout

- WeatherWidget v1.9 remains published and supported.
- WidgetScreen launches as a separate product, separate DMG, separate Applications entry.
- On WidgetScreen first launch, if WeatherWidget is detected at `/Applications/WeatherWidget.app`, offer to import its weather settings (location mode, manual coords, units) as the initial Weather widget configuration. No automatic uninstall.
- A later WeatherWidget release (v1.10) can display an in-app nudge pointing users to WidgetScreen. Out of scope for this spec.

---

## 7. Open Questions for v1.1 / v1.2

These are flagged now so they don't derail v1.0:

- **Stocks API** — Yahoo Finance endpoints are undocumented and unstable; Finnhub free tier is rate-limited. A one-hour spike in v1.1 chooses between them or adopts a user-supplied API key.
- **Focus mode detection** — macOS does not expose a clean public API for current Focus. Research options: DoNotDisturb plist watching, private `_CDDoNotDisturbContext`, or accept "DND only" coverage.
- **Photo widget permissions** — folder scoping vs Full Disk Access. Prefer scoped folder bookmark; verify sandbox compatibility if sandboxing is ever added.

None of these block v1.0.

---

## 8. Success Criteria

v1.0 is considered successful when:

- User installs the DMG, completes onboarding, and sees 6 widgets live on their lock screen within 3 minutes.
- Every v1.0 widget renders correctly at every supported size in both themes.
- Drag-to-place feels instantaneous (sub-frame response to drag).
- Settings changes reflect in the live preview within 100ms.
- Lock / unlock / sleep / wake cycles do not lose widget state or cause visual glitches.
- No crash in the first 24h of personal use on the author's machine across a full lock / work / sleep / travel cycle.

import SwiftUI
import AppKit
import ServiceManagement

enum PreferencesPalette {
    static let canvasTop = Color(red: 0.08, green: 0.12, blue: 0.21)
    static let canvasBottom = Color(red: 0.03, green: 0.05, blue: 0.11)
    static let cardFill = Color.white.opacity(0.08)
    static let cardStroke = Color.white.opacity(0.14)
    static let tileFill = Color.white.opacity(0.05)
    static let tileStroke = Color.white.opacity(0.08)
}

// MARK: - Geocoding types

struct GeocodingResult: Codable, Identifiable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String?
    let admin1: String?
}

struct GeocodingResponse: Codable {
    let results: [GeocodingResult]?
}

// MARK: - Pane Metadata

enum PreferencesPane: String, CaseIterable, Hashable, Identifiable {
    case general, weather, about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .weather: return "Weather"
        case .about: return "About"
        }
    }

    var subtitle: String {
        switch self {
        case .general: return "Choose how WeatherWidget appears and how you reach it."
        case .weather: return "Control location, units, and the details you want on display."
        case .about: return "Version details, links, and project credits."
        }
    }

    var icon: String {
        switch self {
        case .general: return "switch.2"
        case .weather: return "cloud.sun.rain.fill"
        case .about: return "sparkles.rectangle.stack.fill"
        }
    }

    var tint: Color {
        switch self {
        case .general: return Color(red: 0.30, green: 0.68, blue: 1.0)
        case .weather: return Color(red: 0.33, green: 0.86, blue: 0.77)
        case .about: return Color(red: 1.0, green: 0.66, blue: 0.32)
        }
    }
}

// MARK: - Root

struct PreferencesView: View {
    @EnvironmentObject var settings: SettingsStore
    @State private var selection: PreferencesPane = .general

    var body: some View {
        ZStack {
            PreferencesBackground()

            HStack(spacing: 18) {
                PreferencesSidebar(selection: $selection)
                    .frame(width: 250)

                PreferencesDetail(selection: selection)
                    .environmentObject(settings)
            }
            .padding(20)
        }
        .frame(minWidth: 760, minHeight: 540)
    }
}

private struct PreferencesBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [PreferencesPalette.canvasTop, PreferencesPalette.canvasBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(Color.cyan.opacity(0.15))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: -250, y: -180)
            Circle()
                .fill(Color.orange.opacity(0.12))
                .frame(width: 340, height: 340)
                .blur(radius: 110)
                .offset(x: 340, y: -200)
            Circle()
                .fill(Color.blue.opacity(0.16))
                .frame(width: 420, height: 420)
                .blur(radius: 130)
                .offset(x: 240, y: 260)
        }
        .ignoresSafeArea()
    }
}

private struct PreferencesSidebar: View {
    @Binding var selection: PreferencesPane

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Label("WeatherWidget", systemImage: "cloud.sun.fill")
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                Text("Refined controls for how the widget feels on your Mac.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 10) {
                ForEach(PreferencesPane.allCases) { pane in
                    SidebarPaneButton(pane: pane, isSelected: selection == pane) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                            selection = pane
                        }
                    }
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("Quick tip")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.56))
                    .textCase(.uppercase)

                Text("Turning off the menu bar icon keeps the app available in your Dock so settings are still one click away.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                    )
            )
        }
        .padding(20)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
    }
}

private struct SidebarPaneButton: View {
    let pane: PreferencesPane
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    pane.tint.opacity(isSelected ? 0.95 : 0.55),
                                    pane.tint.opacity(isSelected ? 0.55 : 0.25),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: pane.icon)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(pane.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(pane.subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(isSelected ? Color.white.opacity(0.10) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .strokeBorder(Color.white.opacity(isSelected ? 0.16 : 0.05), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 22))
    }
}

private struct PreferencesDetail: View {
    let selection: PreferencesPane

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )

            Group {
                switch selection {
                case .general:
                    GeneralPane()
                case .weather:
                    WeatherPane()
                case .about:
                    AboutPane()
                }
            }
        }
    }
}

private struct PaneHeroCard: View {
    let pane: PreferencesPane
    let badge: String

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [pane.tint.opacity(0.95), pane.tint.opacity(0.35)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: pane.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 8) {
                Text(pane.title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text(pane.subtitle)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.74))
                    .fixedSize(horizontal: false, vertical: true)

                Text(badge)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.10)))
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(
                    LinearGradient(
                        colors: [
                            pane.tint.opacity(0.22),
                            Color.white.opacity(0.05),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .strokeBorder(Color.white.opacity(0.13), lineWidth: 1)
                )
        )
    }
}

private struct SettingsCard<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let content: Content

    init(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(tint.opacity(0.16))
                    Image(systemName: icon)
                        .font(.headline)
                        .foregroundStyle(tint)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.68))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            content
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(PreferencesPalette.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .strokeBorder(PreferencesPalette.cardStroke, lineWidth: 1)
                )
        )
    }
}

private struct SettingsControlBlock<Content: View>: View {
    let title: String
    let description: String
    let content: Content

    init(title: String, description: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.description = description
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.66))
                .fixedSize(horizontal: false, vertical: true)

            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(PreferencesPalette.tileFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(PreferencesPalette.tileStroke, lineWidth: 1)
                )
        )
    }
}

private struct SettingsToggleTile: View {
    let title: String
    let description: String
    let systemImage: String
    let tint: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(tint.opacity(0.18))
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(tint)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.66))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(tint)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(PreferencesPalette.tileFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(PreferencesPalette.tileStroke, lineWidth: 1)
                )
        )
    }
}

private struct SettingsLinkTile: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(tint.opacity(0.18))
                    Image(systemName: systemImage)
                        .font(.headline)
                        .foregroundStyle(tint)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.66))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(PreferencesPalette.tileFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .strokeBorder(PreferencesPalette.tileStroke, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - General Pane

struct GeneralPane: View {
    @EnvironmentObject var settings: SettingsStore
    @State private var launchAtLogin = false
    @State private var launchAtLoginError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PaneHeroCard(
                    pane: .general,
                    badge: settings.showMenuBarIcon ? "Menu bar mode enabled" : "Dock mode enabled"
                )

                SettingsCard(
                    title: "Startup & Access",
                    subtitle: "Decide how WeatherWidget starts and where it stays accessible.",
                    icon: "power.circle.fill",
                    tint: .cyan
                ) {
                    SettingsToggleTile(
                        title: "Launch at Login",
                        description: "Start WeatherWidget automatically when you sign in.",
                        systemImage: "power",
                        tint: .cyan,
                        isOn: $launchAtLogin
                    )
                    .onChange(of: launchAtLogin) { enabled in
                        updateLaunchAtLogin(enabled)
                    }

                    SettingsToggleTile(
                        title: "Show Menu Bar Icon",
                        description: "Keep the weather icon in the menu bar. Turning this off keeps the app in your Dock so you can still reopen settings.",
                        systemImage: "menubar.rectangle",
                        tint: .indigo,
                        isOn: $settings.showMenuBarIcon
                    )

                    SettingsToggleTile(
                        title: "Hide After Unlock",
                        description: "Dismiss the floating widget after the screen unlocks.",
                        systemImage: "lock.open.display",
                        tint: .orange,
                        isOn: $settings.autoHideOnUnlock
                    )

                    if let launchAtLoginError {
                        Text(launchAtLoginError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                SettingsCard(
                    title: "Placement",
                    subtitle: "Shape the widget and place it exactly where it feels at home.",
                    icon: "macwindow.on.rectangle",
                    tint: .blue
                ) {
                    SettingsControlBlock(
                        title: "Widget Size",
                        description: settings.widgetSize.footerDescription
                    ) {
                        Picker("Widget Size", selection: $settings.widgetSize) {
                            ForEach(WidgetSize.allCases, id: \.self) { size in
                                Text(size.fullLabel).tag(size)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }

                    SettingsControlBlock(
                        title: "Widget Position",
                        description: "Pick the corner that feels least intrusive on your chosen display."
                    ) {
                        PositionPickerRow(selection: $settings.position)
                    }

                    if NSScreen.screens.count > 1 {
                        SettingsControlBlock(
                            title: "Display",
                            description: "Send the widget to a specific screen when multiple displays are connected."
                        ) {
                            ScreenPickerRow(selection: $settings.targetScreenName)
                        }
                    }
                }

                SettingsCard(
                    title: "Appearance & Refresh",
                    subtitle: "Balance atmosphere, translucency, and update rhythm.",
                    icon: "dial.medium.fill",
                    tint: .mint
                ) {
                    SettingsControlBlock(
                        title: "Auto-Refresh",
                        description: "Choose how often the widget asks for fresh weather data."
                    ) {
                        Picker("Refresh Interval", selection: $settings.refreshInterval) {
                            ForEach(RefreshInterval.allCases, id: \.self) { interval in
                                Text(interval.label).tag(interval)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }

                    SettingsControlBlock(
                        title: "Glass Style",
                        description: settings.glassStyle == .frosted
                            ? "Frosted uses a denser blur for stronger separation from your wallpaper."
                            : "Clear keeps the panel airy so more of your wallpaper shines through."
                    ) {
                        VStack(alignment: .leading, spacing: 14) {
                            Picker("Glass Style", selection: $settings.glassStyle) {
                                ForEach(GlassStyle.allCases, id: \.self) { style in
                                    Text(style.label).tag(style)
                                }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()

                            if settings.glassStyle == .frosted {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Opacity")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Text("\(Int(settings.frostedOpacity * 100))%")
                                            .font(.subheadline.monospacedDigit())
                                            .foregroundStyle(.white.opacity(0.72))
                                    }

                                    Slider(value: $settings.frostedOpacity, in: 0.3...1.0)
                                        .tint(.white.opacity(0.86))
                                }
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginError = nil
        } catch {
            launchAtLogin = !enabled
            launchAtLoginError = error.localizedDescription
        }
    }
}

// MARK: - Widget Size helpers

extension WidgetSize {
    var fullLabel: String {
        switch self {
        case .compact: return "Compact"
        case .standard: return "Standard"
        case .large: return "Large"
        }
    }

    var footerDescription: String {
        switch self {
        case .compact: return "Temperature and conditions only for the lightest footprint."
        case .standard: return "Balanced layout with the full detail panel."
        case .large: return "Expanded layout with the detail panel and forecast."
        }
    }
}

// MARK: - Position Picker

struct PositionPickerRow: View {
    @Binding var selection: WidgetPosition

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.09), Color.white.opacity(0.03)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                    )

                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                VStack {
                    HStack {
                        cornerButton(.topLeft)
                        Spacer()
                        cornerButton(.topRight)
                    }
                    Spacer()
                    HStack {
                        cornerButton(.bottomLeft)
                        Spacer()
                        cornerButton(.bottomRight)
                    }
                }
                .padding(14)
            }
            .frame(width: 160, height: 104)

            VStack(alignment: .leading, spacing: 6) {
                Text(selection.fullLabel)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("Choose a corner to anchor the floating weather card.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.66))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    private func cornerButton(_ pos: WidgetPosition) -> some View {
        let isSelected = selection == pos

        return Button {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                selection = pos
            }
        } label: {
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.cyan : Color.white.opacity(0.22))
                .frame(width: 34, height: 22)
                .overlay {
                    if isSelected {
                        Image(systemName: "cloud.sun.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                }
                .shadow(color: isSelected ? Color.cyan.opacity(0.45) : .clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(pos.fullLabel))
        .help(pos.fullLabel)
    }
}

// MARK: - Screen Picker

struct ScreenPickerRow: View {
    @Binding var selection: String

    var body: some View {
        Picker("Screen", selection: $selection) {
            Text("Main Display").tag("")
            ForEach(NSScreen.screens, id: \.localizedName) { screen in
                Text(screen.localizedName).tag(screen.localizedName)
            }
        }
        .pickerStyle(.menu)
        .tint(.white)
    }
}

// MARK: - Weather Pane

struct WeatherPane: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PaneHeroCard(
                    pane: .weather,
                    badge: settings.locationMode == .auto
                        ? "Location set automatically"
                        : (settings.manualCityName.isEmpty ? "Custom location pending" : settings.manualCityName)
                )

                LocationSettingsCard()

                SettingsCard(
                    title: "Units",
                    subtitle: "Match the weather presentation to your habits and locale.",
                    icon: "thermometer.medium",
                    tint: .teal
                ) {
                    SettingsControlBlock(
                        title: "Temperature",
                        description: "Choose the scale used throughout the widget."
                    ) {
                        Picker("Temperature Unit", selection: $settings.tempUnit) {
                            ForEach(TempUnit.allCases, id: \.self) { unit in
                                Text(unit.label).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }

                    SettingsControlBlock(
                        title: "Wind Speed",
                        description: "Display wind using the unit you read most naturally."
                    ) {
                        Picker("Wind Unit", selection: $settings.windUnit) {
                            ForEach(WindUnit.allCases, id: \.self) { unit in
                                Text(unit.label).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }

                    SettingsControlBlock(
                        title: "Sunrise & Sunset",
                        description: "Auto follows your locale, or you can force 12-hour or 24-hour time."
                    ) {
                        Picker("Time Format", selection: $settings.timeFormat) {
                            ForEach(TimeFormat.allCases, id: \.self) { format in
                                Text(format.label).tag(format)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                }

                SettingsCard(
                    title: "Visible Details",
                    subtitle: "Choose the supporting data points shown in the widget.",
                    icon: "square.grid.2x2.fill",
                    tint: .blue
                ) {
                    ForEach(DetailCell.allCases) { cell in
                        let isLast = settings.visibleDetailCells.count == 1 && settings.visibleDetailCells.contains(cell)
                        SettingsToggleTile(
                            title: cell.label,
                            description: "Show \(cell.shortLabel.lowercased()) in the expanded weather details.",
                            systemImage: cell.icon,
                            tint: .blue,
                            isOn: detailCellBinding(cell)
                        )
                        .opacity(isLast ? 0.5 : 1.0)
                        .disabled(isLast)
                    }
                    if settings.visibleDetailCells.count == 1 {
                        Text("At least one detail must remain visible.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.horizontal, 4)
                            .padding(.top, 2)
                    }
                }

                SettingsCard(
                    title: "Data Sources",
                    subtitle: "WeatherWidget is intentionally lightweight and keyless.",
                    icon: "externaldrive.fill.badge.checkmark",
                    tint: .orange
                ) {
                    SettingsControlBlock(
                        title: "Current Services",
                        description: "These providers power weather, geocoding, and automatic location detection."
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weather: Open-Meteo")
                            Text("Geocoding: Open-Meteo")
                            Text("Automatic location: ipwho.is")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                    }
                }
            }
            .padding(24)
        }
        .scrollIndicators(.hidden)
    }

    private func detailCellBinding(_ cell: DetailCell) -> Binding<Bool> {
        Binding(
            get: { settings.visibleDetailCells.contains(cell) },
            set: { enabled in
                var cells = settings.visibleDetailCells
                if enabled {
                    cells.insert(cell)
                } else if cells.count > 1 {
                    cells.remove(cell)
                }
                settings.visibleDetailCells = cells
            }
        )
    }
}

// MARK: - Shared Location Search

struct LocationSearchView: View {
    @EnvironmentObject var settings: SettingsStore
    @State private var searchText = ""
    @State private var results: [GeocodingResult] = []
    @State private var isSearching = false
    @State private var searchError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !settings.manualCityName.isEmpty {
                Text(settings.manualCityName)
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            HStack(spacing: 10) {
                TextField("Search city", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { Task { await search() } }

                Button("Search", systemImage: "magnifyingglass") {
                    Task { await search() }
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
                .disabled(isSearching)
            }

            if isSearching {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Searching…")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.66))
                }
            } else if let searchError {
                Text(searchError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            } else if !results.isEmpty {
                VStack(spacing: 10) {
                    ForEach(results) { result in
                        Button {
                            select(result)
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(result.name)
                                        .font(.headline)
                                        .foregroundStyle(.white)

                                    let subtitle = [result.admin1, result.country]
                                        .compactMap { $0 }
                                        .joined(separator: ", ")

                                    if !subtitle.isEmpty {
                                        Text(subtitle)
                                            .font(.subheadline)
                                            .foregroundStyle(.white.opacity(0.66))
                                    }
                                }

                                Spacer(minLength: 0)

                                if settings.manualCityName == result.name &&
                                    abs(settings.manualLatitude - result.latitude) < 0.01 {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.mint)
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func search() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        isSearching = true
        searchError = nil
        results = []

        do {
            var comps = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
            comps.queryItems = [
                .init(name: "name", value: query),
                .init(name: "count", value: "5"),
                .init(name: "language", value: "en"),
                .init(name: "format", value: "json"),
            ]

            let (data, _) = try await URLSession.shared.data(from: comps.url!)
            let response = try JSONDecoder().decode(GeocodingResponse.self, from: data)
            results = response.results ?? []

            if results.isEmpty {
                searchError = "No cities found for \"\(query)\"."
            }
        } catch {
            searchError = "Search failed. Check your connection and try again."
        }

        isSearching = false
    }

    private func select(_ result: GeocodingResult) {
        settings.manualCityName = result.name
        settings.manualLatitude = result.latitude
        settings.manualLongitude = result.longitude
        results = []
        searchText = ""
    }
}

// MARK: - Location Settings Card

private struct LocationSettingsCard: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        SettingsCard(
            title: "Location",
            subtitle: "Stay automatic, or search for a city and keep it pinned.",
            icon: "location.fill",
            tint: .mint
        ) {
            SettingsControlBlock(
                title: "Location Mode",
                description: "Automatic uses your IP address. Custom lets you search for a city manually."
            ) {
                Picker("Location Mode", selection: $settings.locationMode) {
                    ForEach(LocationMode.allCases, id: \.self) { mode in
                        Text(mode == .auto ? "Auto" : "Custom City").tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            if settings.locationMode == .manual {
                SettingsControlBlock(
                    title: settings.manualCityName.isEmpty ? "Choose a City" : "Current City",
                    description: settings.manualCityName.isEmpty
                        ? "Search for a place below, then select the match you want WeatherWidget to use."
                        : "Weather data is currently locked to \(settings.manualCityName)."
                ) {
                    LocationSearchView()
                }
            }
        }
    }
}

// MARK: - About Pane

struct AboutPane: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PaneHeroCard(
                    pane: .about,
                    badge: "Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–")"
                )

                SettingsCard(
                    title: "Project",
                    subtitle: "A lock-screen friendly weather companion for macOS.",
                    icon: "cloud.sun.fill",
                    tint: .orange
                ) {
                    SettingsControlBlock(
                        title: "WeatherWidget",
                        description: "Built for a calm, glanceable weather experience that feels native on the desktop."
                    ) {
                        HStack(spacing: 12) {
                            Text("macOS")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.orange.opacity(0.18)))

                            Text("MIT License")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.76))
                        }
                    }
                }

                SettingsCard(
                    title: "Links",
                    subtitle: "Source, support, and the services that make the app possible.",
                    icon: "link.circle.fill",
                    tint: .blue
                ) {
                    SettingsLinkTile(
                        title: "View Source on GitHub",
                        subtitle: "Browse the repository and track development.",
                        systemImage: "chevron.left.forwardslash.chevron.right",
                        tint: .blue,
                        url: "https://github.com/sam-cookr/WeatherWidget"
                    )

                    SettingsLinkTile(
                        title: "Report an Issue",
                        subtitle: "Open a bug report or feature request.",
                        systemImage: "exclamationmark.bubble.fill",
                        tint: .orange,
                        url: "https://github.com/sam-cookr/WeatherWidget/issues"
                    )
                }

                SettingsCard(
                    title: "Acknowledgements",
                    subtitle: "Thanks to the APIs and libraries behind the scenes.",
                    icon: "heart.text.square.fill",
                    tint: .mint
                ) {
                    SettingsLinkTile(
                        title: "Open-Meteo",
                        subtitle: "Weather and geocoding APIs.",
                        systemImage: "cloud.fill",
                        tint: .mint,
                        url: "https://open-meteo.com"
                    )

                    SettingsLinkTile(
                        title: "ipwho.is",
                        subtitle: "Automatic location lookup.",
                        systemImage: "location.fill",
                        tint: .indigo,
                        url: "https://ipwho.is"
                    )

                    SettingsLinkTile(
                        title: "SkyLightWindow",
                        subtitle: "Window placement support by Lakr233.",
                        systemImage: "macwindow",
                        tint: .cyan,
                        url: "https://github.com/Lakr233/SkyLightWindow"
                    )
                }

                Text("MIT License · © 2026 Sam Cook")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.62))
                    .padding(.horizontal, 4)
            }
            .padding(24)
        }
        .scrollIndicators(.hidden)
    }
}

import SwiftUI
import AppKit
import ServiceManagement

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
        case .general: return "Startup, placement, and widget behavior."
        case .weather: return "Location, units, and visible weather details."
        case .about: return "Version, links, and project credits."
        }
    }

    var icon: String {
        switch self {
        case .general: return "switch.2"
        case .weather: return "cloud.sun"
        case .about: return "info.circle"
        }
    }
}

struct PreferencesView: View {
    @EnvironmentObject var settings: SettingsStore
    @State private var selection: PreferencesPane = .general

    var body: some View {
        ZStack {
            PreferencesBackground()

            HStack(spacing: 20) {
                PreferencesSidebar(selection: $selection)
                    .frame(width: 260)

                PreferencesDetail(selection: selection)
                    .environmentObject(settings)
            }
            .padding(22)
        }
        .frame(minWidth: 760, minHeight: 540)
    }
}

private struct PreferencesBackground: View {
    var body: some View {
        WidgetPalette.preferencesCanvas
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 360, height: 360)
                    .blur(radius: 90)
                    .offset(x: -120, y: -140)
            }
            .overlay(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.white.opacity(0.03))
                    .frame(width: 320, height: 320)
                    .blur(radius: 100)
                    .offset(x: 120, y: 120)
            }
            .ignoresSafeArea()
    }
}

private struct PreferencesSidebar: View {
    @Binding var selection: PreferencesPane

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("WeatherWidget")
                    .font(WidgetTypography.prefsSection)
                    .foregroundStyle(WidgetPalette.primaryText)

                Text("Refined controls for a cleaner, more Apple-like weather utility.")
                    .font(WidgetTypography.prefsBody)
                    .foregroundStyle(WidgetPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 8) {
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
                    .font(WidgetTypography.prefsCaption)
                    .foregroundStyle(WidgetPalette.quaternaryText)
                    .textCase(.uppercase)
                    .tracking(0.8)

                Text("Turning off the menu bar icon keeps the app available in the Dock so settings are still one click away.")
                    .font(WidgetTypography.prefsBody)
                    .foregroundStyle(WidgetPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
            .background(preferencesPanelBackground(cornerRadius: 24))
        }
        .padding(22)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(preferencesPanelBackground(cornerRadius: 30))
    }
}

private struct SidebarPaneButton: View {
    let pane: PreferencesPane
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: pane.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSelected ? WidgetPalette.primaryText : WidgetPalette.secondaryText)
                    .frame(width: 18, height: 18)

                VStack(alignment: .leading, spacing: 3) {
                    Text(pane.title)
                        .font(WidgetTypography.prefsRowTitle)
                        .foregroundStyle(WidgetPalette.primaryText)

                    Text(pane.subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(WidgetPalette.tertiaryText)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? WidgetPalette.selectedFill : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(isSelected ? WidgetPalette.borderPrimary : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PreferencesDetail: View {
    let selection: PreferencesPane

    var body: some View {
        ZStack {
            preferencesPanelBackground(cornerRadius: 32)

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
            .padding(2)
        }
    }
}

private struct PaneHeroCard: View {
    let pane: PreferencesPane
    let badge: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: pane.icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(WidgetPalette.secondaryText)
                    .frame(width: 28, height: 28)
                    .background(preferencesTileBackground(cornerRadius: 14))

                Text(pane.title)
                    .font(WidgetTypography.prefsHero)
                    .foregroundStyle(WidgetPalette.primaryText)
            }

            Text(pane.subtitle)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(WidgetPalette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Text(badge)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(WidgetPalette.primaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(preferencesTileBackground(cornerRadius: 999))
        }
        .padding(24)
        .background(preferencesPanelBackground(cornerRadius: 28))
    }
}

private struct SettingsCard<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let content: Content

    init(title: String, subtitle: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(WidgetPalette.secondaryText)
                    .frame(width: 30, height: 30)
                    .background(preferencesTileBackground(cornerRadius: 15))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(WidgetTypography.prefsCardTitle)
                        .foregroundStyle(WidgetPalette.primaryText)
                    Text(subtitle)
                        .font(WidgetTypography.prefsBody)
                        .foregroundStyle(WidgetPalette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            content
        }
        .padding(22)
        .background(preferencesPanelBackground(cornerRadius: 26))
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
                .font(WidgetTypography.prefsRowTitle)
                .foregroundStyle(WidgetPalette.primaryText)

            Text(description)
                .font(WidgetTypography.prefsBody)
                .foregroundStyle(WidgetPalette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(preferencesTileBackground(cornerRadius: 22))
    }
}

private struct SettingsToggleTile: View {
    let title: String
    let description: String
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(WidgetPalette.secondaryText)
                .frame(width: 30, height: 30)
                .background(preferencesTileBackground(cornerRadius: 15))

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(WidgetTypography.prefsRowTitle)
                    .foregroundStyle(WidgetPalette.primaryText)

                Text(description)
                    .font(WidgetTypography.prefsBody)
                    .foregroundStyle(WidgetPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(.white)
        }
        .padding(18)
        .background(preferencesTileBackground(cornerRadius: 22))
    }
}

private struct SettingsLinkTile: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(WidgetPalette.secondaryText)
                    .frame(width: 30, height: 30)
                    .background(preferencesTileBackground(cornerRadius: 15))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(WidgetTypography.prefsRowTitle)
                        .foregroundStyle(WidgetPalette.primaryText)
                    Text(subtitle)
                        .font(WidgetTypography.prefsBody)
                        .foregroundStyle(WidgetPalette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(WidgetPalette.tertiaryText)
            }
            .padding(18)
            .background(preferencesTileBackground(cornerRadius: 22))
        }
        .buttonStyle(.plain)
    }
}

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
                    icon: "power"
                ) {
                    SettingsToggleTile(
                        title: "Launch at Login",
                        description: "Start WeatherWidget automatically when you sign in.",
                        systemImage: "power",
                        isOn: $launchAtLogin
                    )
                    .onChange(of: launchAtLogin) { enabled in
                        updateLaunchAtLogin(enabled)
                    }

                    SettingsToggleTile(
                        title: "Show Menu Bar Icon",
                        description: "Keep the weather icon in the menu bar. Turning this off keeps the app in your Dock so you can still reopen settings.",
                        systemImage: "menubar.rectangle",
                        isOn: $settings.showMenuBarIcon
                    )

                    SettingsToggleTile(
                        title: "Hide After Unlock",
                        description: "Dismiss the floating widget after the screen unlocks.",
                        systemImage: "lock.open.display",
                        isOn: $settings.autoHideOnUnlock
                    )

                    if let launchAtLoginError {
                        Text(launchAtLoginError)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.red.opacity(0.9))
                    }
                }

                SettingsCard(
                    title: "Placement",
                    subtitle: "Shape the widget and place it exactly where it feels at home.",
                    icon: "macwindow"
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
                    icon: "dial.medium"
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
                                            .font(WidgetTypography.prefsRowTitle)
                                            .foregroundStyle(WidgetPalette.primaryText)
                                        Spacer()
                                        Text("\(Int(settings.frostedOpacity * 100))%")
                                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                            .foregroundStyle(WidgetPalette.secondaryText)
                                    }

                                    Slider(value: $settings.frostedOpacity, in: 0.3...1.0)
                                        .tint(.white)
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

struct PositionPickerRow: View {
    @Binding var selection: WidgetPosition

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(WidgetPalette.surfaceTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(WidgetPalette.borderSecondary, lineWidth: 1)
                    )

                Rectangle()
                    .fill(WidgetPalette.divider)
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
                    .font(WidgetTypography.prefsRowTitle)
                    .foregroundStyle(WidgetPalette.primaryText)

                Text("Choose a corner to anchor the floating weather card.")
                    .font(WidgetTypography.prefsBody)
                    .foregroundStyle(WidgetPalette.secondaryText)
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
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? WidgetPalette.selectedFill : WidgetPalette.surfacePrimary)
                .frame(width: 34, height: 22)
                .overlay {
                    if isSelected {
                        Image(systemName: "cloud.sun.fill")
                            .font(.caption.bold())
                            .foregroundStyle(WidgetPalette.primaryText)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(isSelected ? WidgetPalette.borderPrimary : WidgetPalette.borderSecondary, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(pos.fullLabel))
        .help(pos.fullLabel)
    }
}

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
                    icon: "thermometer.medium"
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
                    icon: "square.grid.2x2"
                ) {
                    ForEach(DetailCell.allCases) { cell in
                        let isLast = settings.visibleDetailCells.count == 1 && settings.visibleDetailCells.contains(cell)
                        SettingsToggleTile(
                            title: cell.label,
                            description: "Show \(cell.shortLabel.lowercased()) in the expanded weather details.",
                            systemImage: cell.icon,
                            isOn: detailCellBinding(cell)
                        )
                        .opacity(isLast ? 0.5 : 1.0)
                        .disabled(isLast)
                    }

                    if settings.visibleDetailCells.count == 1 {
                        Text("At least one detail must remain visible.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(WidgetPalette.tertiaryText)
                            .padding(.horizontal, 4)
                            .padding(.top, 2)
                    }
                }

                SettingsCard(
                    title: "Data Sources",
                    subtitle: "WeatherWidget is intentionally lightweight and keyless.",
                    icon: "externaldrive"
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
                        .font(WidgetTypography.prefsBody)
                        .foregroundStyle(WidgetPalette.secondaryText)
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
                    .font(WidgetTypography.prefsRowTitle)
                    .foregroundStyle(WidgetPalette.primaryText)
            }

            HStack(spacing: 10) {
                TextField("Search city", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(WidgetTypography.prefsBody)
                    .foregroundStyle(WidgetPalette.primaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(preferencesTileBackground(cornerRadius: 14))
                    .onSubmit { Task { await search() } }

                Button("Search") {
                    Task { await search() }
                }
                .buttonStyle(.plain)
                .font(WidgetTypography.prefsRowTitle)
                .foregroundStyle(WidgetPalette.primaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(preferencesTileBackground(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(WidgetPalette.borderPrimary, lineWidth: 1)
                )
                .disabled(isSearching)
            }

            if isSearching {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Searching…")
                        .font(WidgetTypography.prefsBody)
                        .foregroundStyle(WidgetPalette.secondaryText)
                }
            } else if let searchError {
                Text(searchError)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.red.opacity(0.9))
            } else if !results.isEmpty {
                VStack(spacing: 10) {
                    ForEach(results) { result in
                        Button {
                            select(result)
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(result.name)
                                        .font(WidgetTypography.prefsRowTitle)
                                        .foregroundStyle(WidgetPalette.primaryText)

                                    let subtitle = [result.admin1, result.country]
                                        .compactMap { $0 }
                                        .joined(separator: ", ")

                                    if !subtitle.isEmpty {
                                        Text(subtitle)
                                            .font(WidgetTypography.prefsBody)
                                            .foregroundStyle(WidgetPalette.secondaryText)
                                    }
                                }

                                Spacer(minLength: 0)

                                if settings.manualCityName == result.name &&
                                    abs(settings.manualLatitude - result.latitude) < 0.01 {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(WidgetPalette.primaryText)
                                }
                            }
                            .padding(14)
                            .background(preferencesTileBackground(cornerRadius: 18))
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

private struct LocationSettingsCard: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        SettingsCard(
            title: "Location",
            subtitle: "Stay automatic, or search for a city and keep it pinned.",
            icon: "location"
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

struct AboutPane: View {
    private var versionBadge: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        return "Version \(version)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PaneHeroCard(
                    pane: .about,
                    badge: versionBadge
                )

                SettingsCard(
                    title: "Project",
                    subtitle: "A lock-screen friendly weather companion for macOS.",
                    icon: "cloud.sun"
                ) {
                    SettingsControlBlock(
                        title: "WeatherWidget",
                        description: "Built for a calm, glanceable weather experience that feels native on the desktop."
                    ) {
                        HStack(spacing: 12) {
                            Text("macOS")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(WidgetPalette.primaryText)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(preferencesTileBackground(cornerRadius: 999))

                            Text("MIT License")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(WidgetPalette.secondaryText)
                        }
                    }
                }

                SettingsCard(
                    title: "Links",
                    subtitle: "Source, support, and the services that make the app possible.",
                    icon: "link"
                ) {
                    SettingsLinkTile(
                        title: "View Source on GitHub",
                        subtitle: "Browse the repository and track development.",
                        systemImage: "chevron.left.forwardslash.chevron.right",
                        url: "https://github.com/sam-cookr/WeatherWidget"
                    )

                    SettingsLinkTile(
                        title: "Report an Issue",
                        subtitle: "Open a bug report or feature request.",
                        systemImage: "exclamationmark.bubble",
                        url: "https://github.com/sam-cookr/WeatherWidget/issues"
                    )
                }

                SettingsCard(
                    title: "Acknowledgements",
                    subtitle: "Thanks to the APIs and libraries behind the scenes.",
                    icon: "heart.text.square"
                ) {
                    SettingsLinkTile(
                        title: "Open-Meteo",
                        subtitle: "Weather and geocoding APIs.",
                        systemImage: "cloud",
                        url: "https://open-meteo.com"
                    )

                    SettingsLinkTile(
                        title: "ipwho.is",
                        subtitle: "Automatic location lookup.",
                        systemImage: "location",
                        url: "https://ipwho.is"
                    )

                    SettingsLinkTile(
                        title: "SkyLightWindow",
                        subtitle: "Window placement support by Lakr233.",
                        systemImage: "macwindow",
                        url: "https://github.com/Lakr233/SkyLightWindow"
                    )
                }

                Text("MIT License · © 2026 Sam Cook")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WidgetPalette.tertiaryText)
                    .padding(.horizontal, 4)
            }
            .padding(24)
        }
        .scrollIndicators(.hidden)
    }
}

private func preferencesPanelBackground(cornerRadius: CGFloat) -> some View {
    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .fill(WidgetPalette.preferencesPanel)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(WidgetPalette.borderSecondary, lineWidth: 1)
        )
}

private func preferencesTileBackground(cornerRadius: CGFloat) -> some View {
    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .fill(WidgetPalette.preferencesTile)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(WidgetPalette.borderSecondary, lineWidth: 1)
        )
}

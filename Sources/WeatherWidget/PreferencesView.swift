import WidgetScreenCore
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

            HStack(spacing: PreferencesChrome.columnSpacing) {
                PreferencesSidebar(selection: $selection)
                    .frame(width: PreferencesChrome.sidebarWidth)

                PreferencesDetail(selection: selection)
                    .environmentObject(settings)
                    .frame(maxWidth: .infinity)

                LivePreviewPane()
                    .environmentObject(settings)
                    .frame(width: PreferencesChrome.previewWidth)
            }
            .padding(PreferencesChrome.windowPadding)
        }
        .frame(minWidth: 960, minHeight: 540)
    }
}

private enum PreferencesChrome {
    static let windowPadding: CGFloat = 18
    static let columnSpacing: CGFloat = 16
    static let sidebarWidth: CGFloat = 236
    static let previewWidth: CGFloat = 236
    static let panelRadius: CGFloat = 26
    static let tileRadius: CGFloat = 16
    static let rowPadding = EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
}

private struct PreferencesBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.085, green: 0.087, blue: 0.096),
                Color(red: 0.035, green: 0.036, blue: 0.042),
                Color.black.opacity(0.98),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
            .overlay {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.18)
            }
            .overlay(
                LinearGradient(
                    colors: [.white.opacity(0.05), .clear, .black.opacity(0.22)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .ignoresSafeArea()
    }
}

private struct PreferencesSidebar: View {
    @Binding var selection: PreferencesPane
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text("WeatherWidget")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(WidgetPalette.primaryText)

                Text("Lock-screen weather, tuned quietly.")
                    .font(WidgetTypography.prefsBody)
                    .foregroundStyle(WidgetPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 8) {
                ForEach(PreferencesPane.allCases) { pane in
                    SidebarPaneButton(pane: pane, isSelected: selection == pane) {
                        withAnimation(Motion.spring(Motion.defaultSpring, reduceMotion: reduceMotion)) {
                            selection = pane
                        }
                    }
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 10) {
                Label("Live Preview", systemImage: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WidgetPalette.secondaryText)

                Text("Changes update the preview immediately.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(WidgetPalette.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(preferencesTileBackground(cornerRadius: PreferencesChrome.tileRadius))
        }
        .padding(18)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(preferencesPanelBackground(cornerRadius: PreferencesChrome.panelRadius))
    }
}

private struct SidebarPaneButton: View {
    let pane: PreferencesPane
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovering = false

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
            .padding(.horizontal, 13)
            .padding(.vertical, 11)
            .background(sidebarItemBackground)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityLabel(pane.title)
    }

    private var sidebarItemBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(isSelected ? Color.white.opacity(0.16) : Color.white.opacity(isHovering ? 0.055 : 0.0))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? Color.white.opacity(0.18) : Color.white.opacity(isHovering ? 0.08 : 0), lineWidth: 1)
            )
            .shadow(color: isSelected ? .black.opacity(0.26) : .clear, radius: 10, x: 0, y: 6)
    }
}

private struct PreferencesDetail: View {
    let selection: PreferencesPane

    var body: some View {
        ZStack {
            preferencesPanelBackground(cornerRadius: PreferencesChrome.panelRadius)

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
            .transition(.opacity)
        }
        .animation(Motion.defaultSpring, value: selection)
    }
}

private struct PaneHeroCard: View {
    let pane: PreferencesPane
    let badge: String

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: pane.icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(WidgetPalette.secondaryText)
                    .frame(width: 32, height: 32)
                    .background(preferencesInsetBackground(cornerRadius: 13))

                VStack(alignment: .leading, spacing: 3) {
                    Text(pane.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(WidgetPalette.primaryText)

                    Text(pane.subtitle)
                        .font(WidgetTypography.prefsBody)
                        .foregroundStyle(WidgetPalette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 12)

            Text(badge)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(WidgetPalette.primaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(preferencesInsetBackground(cornerRadius: 999))
                .lineLimit(1)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(preferencesTileBackground(cornerRadius: 20))
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
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 11) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(WidgetPalette.secondaryText)
                    .frame(width: 28, height: 28)
                    .background(preferencesInsetBackground(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(WidgetPalette.primaryText)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(WidgetPalette.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            content
        }
        .padding(16)
        .background(preferencesTileBackground(cornerRadius: 20))
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
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(WidgetTypography.prefsRowTitle)
                .foregroundStyle(WidgetPalette.primaryText)

            Text(description)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(WidgetPalette.tertiaryText)
                .fixedSize(horizontal: false, vertical: true)

            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(preferencesInsetBackground(cornerRadius: PreferencesChrome.tileRadius))
    }
}

private struct SettingsLinkTile: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let url: String
    @State private var isHovering = false

    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(WidgetPalette.secondaryText)
                    .frame(width: 30, height: 30)
                    .background(preferencesInsetBackground(cornerRadius: 13))

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
                    .foregroundStyle(isHovering ? WidgetPalette.secondaryText : WidgetPalette.tertiaryText)
            }
            .padding(PreferencesChrome.rowPadding)
            .background(preferencesInteractiveTileBackground(isHovering: isHovering, cornerRadius: PreferencesChrome.tileRadius))
            .contentShape(RoundedRectangle(cornerRadius: PreferencesChrome.tileRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

/// Replaces SettingsCard for groups that don't need full-card chrome.
/// Renders a typed section title + hairline, then the content.
private struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(WidgetPalette.tertiaryText)
                    .tracking(0.6)

                Rectangle()
                    .fill(WidgetPalette.divider)
                    .frame(height: 1)
            }
            .padding(.horizontal, 2)

            content
        }
    }
}

/// Flat row: leading SF symbol + label (+ optional description) + trailing control.
/// Use for simple controls that should share the Preferences hover treatment.
private struct SettingsRow<Control: View>: View {
    let icon: String?
    let label: String
    let description: String?
    let control: Control
    @State private var isHovering = false

    init(icon: String? = nil, label: String, description: String? = nil, @ViewBuilder control: () -> Control) {
        self.icon = icon
        self.label = label
        self.description = description
        self.control = control()
    }

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(WidgetPalette.secondaryText)
                    .frame(width: 24, height: 24)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(WidgetTypography.prefsRowLabel)
                    .foregroundStyle(WidgetPalette.primaryText)

                if let description {
                    Text(description)
                        .font(WidgetTypography.prefsBody)
                        .foregroundStyle(WidgetPalette.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()
            control
        }
        .padding(PreferencesChrome.rowPadding)
        .background(preferencesInteractiveTileBackground(isHovering: isHovering, cornerRadius: PreferencesChrome.tileRadius))
        .contentShape(RoundedRectangle(cornerRadius: PreferencesChrome.tileRadius, style: .continuous))
        .onHover { isHovering = $0 }
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

                SettingsSection("Startup & Access") {
                    SettingsRow(icon: "power", label: "Launch at Login",
                                description: "Start automatically when you sign in.") {
                        Toggle("Launch at Login", isOn: $launchAtLogin)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .tint(.white)
                            .accessibilityLabel("Launch at Login")
                    }
                    .onChange(of: launchAtLogin) { enabled in updateLaunchAtLogin(enabled) }

                    SettingsRow(icon: "menubar.rectangle", label: "Show Menu Bar Icon",
                                description: "Keep the weather icon in the menu bar.") {
                        Toggle("Show Menu Bar Icon", isOn: $settings.showMenuBarIcon)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .tint(.white)
                            .accessibilityLabel("Show Menu Bar Icon")
                    }

                    SettingsRow(icon: "lock.open.display", label: "Hide After Unlock",
                                description: "Dismiss the widget when the screen unlocks.") {
                        Toggle("Hide After Unlock", isOn: $settings.autoHideOnUnlock)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .tint(.white)
                            .accessibilityLabel("Hide After Unlock")
                    }

                    if let launchAtLoginError {
                        Text(launchAtLoginError)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(WidgetPalette.tertiaryText)
                            .padding(.horizontal, 4)
                    }
                }

                SettingsSection("Placement") {
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
                        .accessibilityLabel("Widget Size")
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

                SettingsSection("Appearance & Refresh") {
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
                        .accessibilityLabel("Refresh Interval")
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
                            .accessibilityLabel("Glass Style")

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
                                        .accessibilityLabel("Frosted Glass Opacity")
                                        .accessibilityValue("\(Int(settings.frostedOpacity * 100)) percent")
                                }
                            }
                        }
                    }
                }
            }
            .padding(22)
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
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.035))
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
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(WidgetPalette.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    private func cornerButton(_ pos: WidgetPosition) -> some View {
        let isSelected = selection == pos

        return Button {
            withAnimation(Motion.spring(Motion.quickSpring, reduceMotion: reduceMotion)) {
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

                SettingsSection("Units") {
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
                        .accessibilityLabel("Temperature Unit")
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
                        .accessibilityLabel("Wind Speed Unit")
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
                        .accessibilityLabel("Time Format")
                    }
                }

                SettingsSection("Visible Details") {
                    ForEach(DetailCell.allCases) { cell in
                        let isLast = settings.visibleDetailCells.count == 1 && settings.visibleDetailCells.contains(cell)
                        SettingsRow(icon: cell.icon, label: cell.label) {
                            Toggle(cell.label, isOn: detailCellBinding(cell))
                                .labelsHidden()
                                .toggleStyle(.switch)
                                .tint(.white)
                                .accessibilityLabel("Show \(cell.label)")
                        }
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

                SettingsSection("Data Sources") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Weather and geocoding from Open-Meteo", systemImage: "cloud")
                        Label("Automatic location from ipwho.is", systemImage: "location")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WidgetPalette.secondaryText)
                    .padding(PreferencesChrome.rowPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(preferencesInsetBackground(cornerRadius: PreferencesChrome.tileRadius))
                }
            }
            .padding(22)
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
    @State private var selectedIndex: Int = -1
    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !settings.manualCityName.isEmpty && results.isEmpty && !isSearching {
                Text(settings.manualCityName)
                    .font(WidgetTypography.prefsRowTitle)
                    .foregroundStyle(WidgetPalette.primaryText)
            }

            TextField("Search city…", text: $searchText)
                .textFieldStyle(.plain)
                .font(WidgetTypography.prefsBody)
                .foregroundStyle(WidgetPalette.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(preferencesInsetBackground(cornerRadius: 14))
                .focused($fieldFocused)
                .onKeyPressCompat(.escape) {
                    searchText = ""
                    results = []
                    searchError = nil
                }
                .onKeyPressCompat(.upArrow) {
                    if !results.isEmpty { selectedIndex = max(0, selectedIndex - 1) }
                }
                .onKeyPressCompat(.downArrow) {
                    if !results.isEmpty { selectedIndex = min(results.count - 1, selectedIndex + 1) }
                }
                .onKeyPressCompat(.return) {
                    if selectedIndex >= 0, selectedIndex < results.count { select(results[selectedIndex]) }
                }
                .task(id: searchText) {
                    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !query.isEmpty else {
                        results = []
                        searchError = nil
                        isSearching = false
                        return
                    }
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                    await performSearch(query: query)
                }

            if isSearching {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Searching…")
                        .font(WidgetTypography.prefsBody)
                        .foregroundStyle(WidgetPalette.secondaryText)
                }
            } else if let searchError {
                Text(searchError)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WidgetPalette.tertiaryText)
            } else if !results.isEmpty {
                VStack(spacing: 6) {
                    ForEach(Array(results.enumerated()), id: \.element.id) { idx, result in
                        Button { select(result) } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(result.name)
                                        .font(idx == selectedIndex
                                              ? .system(size: 13, weight: .bold)
                                              : WidgetTypography.prefsRowTitle)
                                        .foregroundStyle(WidgetPalette.primaryText)

                                    let subtitle = [result.admin1, result.country]
                                        .compactMap { $0 }.joined(separator: ", ")
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
                            .background(preferencesInteractiveTileBackground(
                                isHovering: idx == selectedIndex,
                                cornerRadius: PreferencesChrome.tileRadius
                            ))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func performSearch(query: String) async {
        isSearching = true
        searchError = nil
        selectedIndex = -1

        do {
            var comps = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
            comps.queryItems = [
                .init(name: "name",     value: query),
                .init(name: "count",    value: "8"),
                .init(name: "language", value: "en"),
                .init(name: "format",   value: "json"),
            ]
            let response: GeocodingResponse = try await NetworkClient.shared.get(comps.url!)
            results = response.results ?? []
            if results.isEmpty { searchError = "No cities found for \"\(query)\"." }
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
        searchError = nil
        selectedIndex = -1
    }
}


private struct LocationSettingsCard: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        SettingsCard(
            title: "Location",
            subtitle: "Use automatic lookup or pin a city.",
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
            .padding(22)
        }
        .scrollIndicators(.hidden)
    }
}

private func preferencesPanelBackground(cornerRadius: CGFloat) -> some View {
    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .fill(Color.white.opacity(0.065))
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.46)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.105), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.28), radius: 24, x: 0, y: 18)
        .shadow(color: .white.opacity(0.035), radius: 1, x: 0, y: 1)
}

private func preferencesTileBackground(cornerRadius: CGFloat) -> some View {
    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .fill(Color.white.opacity(0.052))
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.20)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.085), lineWidth: 1)
        )
}

private func preferencesInsetBackground(cornerRadius: CGFloat) -> some View {
    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .fill(Color.white.opacity(0.035))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
        )
}

private func preferencesInteractiveTileBackground(isHovering: Bool, cornerRadius: CGFloat) -> some View {
    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .fill(Color.white.opacity(isHovering ? 0.075 : 0.04))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(isHovering ? 0.13 : 0.075), lineWidth: 1)
        )
        .shadow(color: isHovering ? .black.opacity(0.18) : .clear, radius: 8, x: 0, y: 5)
}

// Keyboard-nav helper: adds onKeyPress on macOS 14+; silently no-ops on 13.
private extension View {
    @ViewBuilder func onKeyPressCompat(_ key: KeyEquivalent, action: @escaping () -> Void) -> some View {
        if #available(macOS 14, *) {
            self.onKeyPress(key) { action(); return .handled }
        } else {
            self
        }
    }
}

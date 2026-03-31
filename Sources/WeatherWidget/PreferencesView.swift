import SwiftUI
import AppKit
import ServiceManagement

// MARK: - Geocoding types (used by location search)

private struct GeocodingResult: Codable, Identifiable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String?
    let admin1: String?
}

private struct GeocodingResponse: Codable {
    let results: [GeocodingResult]?
}

// MARK: - Root

struct PreferencesView: View {
    @EnvironmentObject var settings: SettingsStore
    @State private var selection: Pane = .general

    enum Pane: String, CaseIterable, Hashable {
        case general, weather, about

        var title: String {
            switch self {
            case .general: return "General"
            case .weather: return "Weather"
            case .about:   return "About"
            }
        }
        var icon: String {
            switch self {
            case .general: return "gearshape.fill"
            case .weather: return "cloud.sun.fill"
            case .about:   return "info.circle.fill"
            }
        }
        var color: Color {
            switch self {
            case .general: return .gray
            case .weather: return .blue
            case .about:   return Color(nsColor: .systemGray)
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(Pane.allCases, id: \.self, selection: $selection) { pane in
                Label {
                    Text(pane.title)
                } icon: {
                    PaneIcon(systemName: pane.icon, color: pane.color)
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            Group {
                switch selection {
                case .general: GeneralPane()
                case .weather: WeatherPane()
                case .about:   AboutPane()
                }
            }
            .navigationTitle(selection.title)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 620, minHeight: 400)
    }
}

// MARK: - Sidebar Icon

struct PaneIcon: View {
    let systemName: String
    let color: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 26, height: 26)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(color.gradient)
            )
    }
}

// MARK: - General Pane

struct GeneralPane: View {
    @EnvironmentObject var settings: SettingsStore
    @State private var launchAtLogin = false
    @State private var launchAtLoginError: String?

    var body: some View {
        Form {
            // ── Startup ──────────────────────────────────────────────────
            Section {
                Toggle(isOn: $launchAtLogin) {
                    Label("Launch at Login", systemImage: "power")
                }
                .onChange(of: launchAtLogin) { enabled in
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

                if let err = launchAtLoginError {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            // ── Widget Size ───────────────────────────────────────────────
            Section {
                Picker("Size", selection: $settings.widgetSize) {
                    ForEach(WidgetSize.allCases, id: \.self) { size in
                        Text(size.fullLabel).tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            } header: {
                Text("Widget Size")
            } footer: {
                Text(settings.widgetSize.footerDescription)
                    .foregroundStyle(.secondary)
            }

            // ── Position ─────────────────────────────────────────────────
            Section("Widget Position") {
                PositionPickerRow(selection: $settings.position)
            }

            // ── Screen ───────────────────────────────────────────────────
            if NSScreen.screens.count > 1 {
                Section("Display") {
                    ScreenPickerRow(selection: $settings.targetScreenName)
                }
            }

            // ── Behaviour ────────────────────────────────────────────────
            Section("Behaviour") {
                Toggle(isOn: $settings.autoHideOnUnlock) {
                    Label("Hide on screen unlock", systemImage: "lock.open")
                }
            }

            // ── Refresh ──────────────────────────────────────────────────
            Section("Auto-Refresh") {
                Picker("Interval", selection: $settings.refreshInterval) {
                    ForEach(RefreshInterval.allCases, id: \.self) { interval in
                        Text(interval.label).tag(interval)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            // ── Glass Style ───────────────────────────────────────────────
            Section {
                Picker("Style", selection: $settings.glassStyle) {
                    ForEach(GlassStyle.allCases, id: \.self) { style in
                        Text(style.label).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                if settings.glassStyle == .frosted {
                    LabeledContent("Opacity") {
                        HStack {
                            Slider(value: $settings.frostedOpacity, in: 0.3...1.0)
                                .frame(width: 160)
                            Text("\(Int(settings.frostedOpacity * 100))%")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
            } header: {
                Text("Widget Glass Style")
            } footer: {
                Text(settings.glassStyle == .frosted
                     ? "Frosted: native compositor blur — opaque on any background."
                     : "Clear: transparent with light reflections — wallpaper shows through.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

// MARK: - Widget Size extensions

extension WidgetSize {
    var fullLabel: String {
        switch self {
        case .compact:  return "Compact"
        case .standard: return "Standard"
        case .large:    return "Large"
        }
    }
    var footerDescription: String {
        switch self {
        case .compact:  return "Temperature and condition only — minimal footprint."
        case .standard: return "Full detail panel with humidity, wind, UV, and more."
        case .large:    return "Detail panel plus a 3-day forecast."
        }
    }
}

// MARK: - Position Picker

struct PositionPickerRow: View {
    @Binding var selection: WidgetPosition

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(.secondary.opacity(0.3), lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.secondary.opacity(0.06))
                    )

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
                .padding(10)
            }
            .frame(width: 130, height: 82)

            VStack(alignment: .leading, spacing: 4) {
                Text(selection.fullLabel)
                    .font(.system(size: 14, weight: .medium))
                Text("Tap a corner to reposition")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func cornerButton(_ pos: WidgetPosition) -> some View {
        let selected = selection == pos
        return Button { selection = pos } label: {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(selected ? Color.accentColor : Color.secondary.opacity(0.2))
                .frame(width: 24, height: 15)
                .overlay {
                    if selected {
                        Image(systemName: "cloud.sun.fill")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .animation(.spring(response: 0.2, dampingFraction: 0.8), value: selected)
        }
        .buttonStyle(.plain)
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
    }
}

// MARK: - Weather Pane

struct WeatherPane: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        Form {
            // ── Location ─────────────────────────────────────────────────
            LocationSection()

            // ── Units ─────────────────────────────────────────────────────
            Section("Temperature") {
                Picker("Unit", selection: $settings.tempUnit) {
                    ForEach(TempUnit.allCases, id: \.self) { unit in
                        Text(unit.label).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Section("Wind Speed") {
                Picker("Unit", selection: $settings.windUnit) {
                    ForEach(WindUnit.allCases, id: \.self) { unit in
                        Text(unit.label).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            // ── Time Format ───────────────────────────────────────────────
            Section {
                Picker("Format", selection: $settings.timeFormat) {
                    ForEach(TimeFormat.allCases, id: \.self) { fmt in
                        Text(fmt.label).tag(fmt)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            } header: {
                Text("Sunrise / Sunset Time")
            } footer: {
                Text("Auto uses your system locale.")
                    .foregroundStyle(.secondary)
            }

            // ── Visible Detail Cells ──────────────────────────────────────
            Section {
                ForEach(DetailCell.allCases) { cell in
                    Toggle(isOn: detailCellBinding(cell)) {
                        Label(cell.label, systemImage: cell.icon)
                    }
                }
            } header: {
                Text("Visible Details")
            } footer: {
                Text("Choose which cells appear in the widget's detail panel.")
                    .foregroundStyle(.secondary)
            }

            // ── Data Sources ──────────────────────────────────────────────
            Section {
                LabeledContent("Weather") {
                    Text("Open-Meteo (free, no API key)")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("IP Location") {
                    Text("ipwho.is")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Data Sources")
            } footer: {
                Text("No account or API key required. Location is not stored on any server.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
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

// MARK: - Location Section

private struct LocationSection: View {
    @EnvironmentObject var settings: SettingsStore
    @State private var searchText = ""
    @State private var results: [GeocodingResult] = []
    @State private var isSearching = false
    @State private var searchError: String?

    var body: some View {
        Section {
            Picker("Mode", selection: $settings.locationMode) {
                ForEach(LocationMode.allCases, id: \.self) { mode in
                    Text(mode == .auto ? "Auto (IP-based)" : "Custom City").tag(mode)
                }
            }
            .onChange(of: settings.locationMode) { _ in
                results = []
                searchText = ""
                searchError = nil
            }

            if settings.locationMode == .manual {
                if !settings.manualCityName.isEmpty {
                    LabeledContent("Current City") {
                        Text(settings.manualCityName)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    TextField("Search city…", text: $searchText)
                        .onSubmit { Task { await search() } }
                    Button("Search") { Task { await search() } }
                        .disabled(isSearching)
                }

                if isSearching {
                    HStack {
                        ProgressView().controlSize(.small)
                        Text("Searching…").foregroundStyle(.secondary)
                    }
                } else if let err = searchError {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else {
                    ForEach(results) { (result: GeocodingResult) in
                        Button(action: { select(result) }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.name)
                                        .foregroundStyle(.primary)
                                    let subtitle = [result.admin1, result.country]
                                        .compactMap { $0 }
                                        .joined(separator: ", ")
                                    if !subtitle.isEmpty {
                                        Text(subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if settings.manualCityName == result.name &&
                                   abs(settings.manualLatitude - result.latitude) < 0.01 {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        } header: {
            Text("Location")
        } footer: {
            if settings.locationMode == .auto {
                Text("Location is automatically detected from your IP address.")
                    .foregroundStyle(.secondary)
            } else if settings.manualCityName.isEmpty {
                Text("Search for a city above to set a custom location.")
                    .foregroundStyle(.secondary)
            } else {
                Text("Weather data will be fetched for \(settings.manualCityName).")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func search() async {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }
        isSearching = true
        searchError = nil
        results = []

        do {
            var comps = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
            comps.queryItems = [
                .init(name: "name",     value: query),
                .init(name: "count",    value: "5"),
                .init(name: "language", value: "en"),
                .init(name: "format",   value: "json"),
            ]
            let (data, _) = try await URLSession.shared.data(from: comps.url!)
            let resp = try JSONDecoder().decode(GeocodingResponse.self, from: data)
            results = resp.results ?? []
            if results.isEmpty { searchError = "No cities found for \"\(query)\"" }
        } catch {
            searchError = "Search failed. Check your connection."
        }
        isSearching = false
    }

    private func select(_ result: GeocodingResult) {
        settings.manualCityName  = result.name
        settings.manualLatitude  = result.latitude
        settings.manualLongitude = result.longitude
        results   = []
        searchText = ""
    }
}

// MARK: - About Pane

struct AboutPane: View {
    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "cloud.sun.fill")
                        .font(.system(size: 36))
                        .symbolRenderingMode(.multicolor)
                        .frame(width: 60, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.blue.opacity(0.1))
                        )
                    VStack(alignment: .leading, spacing: 3) {
                        Text("WeatherWidget")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Version 1.7")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Text("Lock-Screen Weather for macOS")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }

            Section("Links") {
                Link(destination: URL(string: "https://github.com/sam-cookr/WeatherWidget")!) {
                    Label("View Source on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                Link(destination: URL(string: "https://github.com/sam-cookr/WeatherWidget/issues")!) {
                    Label("Report an Issue", systemImage: "exclamationmark.bubble")
                }
            }

            Section("Acknowledgements") {
                Link(destination: URL(string: "https://open-meteo.com")!) {
                    Label("Open-Meteo · Weather API", systemImage: "cloud.fill")
                }
                Link(destination: URL(string: "https://geocoding-api.open-meteo.com")!) {
                    Label("Open-Meteo · Geocoding API", systemImage: "location.circle.fill")
                }
                Link(destination: URL(string: "https://ipwho.is")!) {
                    Label("ipwho.is · Location lookup", systemImage: "location.fill")
                }
                Link(destination: URL(string: "https://github.com/Lakr233/SkyLightWindow")!) {
                    Label("SkyLightWindow by Lakr233", systemImage: "macwindow")
                }
            }

            Section {
                Text("MIT License · © 2026 Sam Cook")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }
        }
        .formStyle(.grouped)
    }
}

import SwiftUI
import ServiceManagement

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

            // ── Position ─────────────────────────────────────────────────
            Section("Widget Position") {
                PositionPickerRow(selection: $settings.position)
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
        }
        .formStyle(.grouped)
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

// MARK: - Position Picker

struct PositionPickerRow: View {
    @Binding var selection: WidgetPosition

    var body: some View {
        HStack(spacing: 20) {
            // Mini screen diagram
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

// MARK: - Weather Pane

struct WeatherPane: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        Form {
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

            Section {
                LabeledContent("Data Source") {
                    Text("Open-Meteo (free, no API key)")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Location") {
                    Text("IP-based via ipapi.co")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Data")
            } footer: {
                Text("No account or API key required. Location is not stored.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
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
                        Text("Version 1.2")
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
                Link(destination: URL(string: "https://ipapi.co")!) {
                    Label("ipapi.co · Location lookup", systemImage: "location.fill")
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

import SwiftUI
import AppKit

// MARK: - Settings Panel

struct SettingsPanel: View {
    @Binding var showSettings: Bool
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            panelHeader

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    SettingsGroup(title: "LOCATION") {
                        SettingRow(label: "Location", icon: "location.fill", iconColor: .mint) {
                            HStack {
                                Text(settings.locationMode == .auto
                                     ? "Auto"
                                     : (settings.manualCityName.isEmpty ? "Custom" : settings.manualCityName))
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.65))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Spacer()
                                Button("Change…") {
                                    NSApp.sendAction(#selector(AppDelegate.openPreferences), to: nil, from: nil)
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.38))
                            }
                        }
                    }

                    SettingsGroup(title: "UNITS") {
                        SettingRow(label: "Temperature", icon: "thermometer.medium", iconColor: .orange) {
                            SegmentPicker(options: Array(TempUnit.allCases), selection: $settings.tempUnit)
                        }
                        RowDivider()
                        SettingRow(label: "Wind Speed", icon: "wind", iconColor: .cyan) {
                            SegmentPicker(options: Array(WindUnit.allCases), selection: $settings.windUnit)
                        }
                        RowDivider()
                        SettingRow(label: "Time Format", icon: "clock.fill", iconColor: .purple) {
                            SegmentPicker(options: Array(TimeFormat.allCases), selection: $settings.timeFormat)
                        }
                    }

                    SettingsGroup(title: "WIDGET") {
                        SettingRow(label: "Size", icon: "rectangle.expand.vertical", iconColor: .green) {
                            SegmentPicker(options: Array(WidgetSize.allCases), selection: $settings.widgetSize)
                        }
                        RowDivider()
                        SettingRow(label: "Position", icon: "arrow.up.left.and.arrow.down.right", iconColor: .blue) {
                            SegmentPicker(options: Array(WidgetPosition.allCases), selection: $settings.position)
                        }
                        RowDivider()
                        SettingRow(label: "Auto-Refresh", icon: "arrow.clockwise", iconColor: .teal) {
                            SegmentPicker(options: Array(RefreshInterval.allCases), selection: $settings.refreshInterval)
                        }
                    }

                    SettingsGroup(title: "APPEARANCE") {
                        SettingRow(label: "Glass Style", icon: "circle.lefthalf.filled", iconColor: .indigo) {
                            SegmentPicker(options: Array(GlassStyle.allCases), selection: $settings.glassStyle)
                        }
                        if settings.glassStyle == .frosted {
                            RowDivider()
                            SettingRow(label: "Opacity", icon: "sun.min", iconColor: Color(red: 1.0, green: 0.72, blue: 0.0)) {
                                OpacitySlider(value: $settings.frostedOpacity)
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 6)
                .padding(.bottom, 14)
            }

            panelFooter
        }
    }

    // MARK: - Header

    private var panelHeader: some View {
        HStack(alignment: .center, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.18), .white.opacity(0.07)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(.white.opacity(0.22), lineWidth: 0.5)
                    )
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(width: 28, height: 28)

            Text("Settings")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    showSettings = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.65))
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(.white.opacity(0.12)))
                    .overlay(Circle().strokeBorder(.white.opacity(0.2), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Footer

    private var panelFooter: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(.white.opacity(0.07))
                .frame(height: 0.5)
                .padding(.horizontal, 12)
            HStack {
                Text("WeatherWidget · Open-Meteo")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.2))
                Spacer()
                Button("All Settings…") {
                    NSApp.sendAction(#selector(AppDelegate.openPreferences), to: nil, from: nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
        }
    }
}

// MARK: - Settings Group

struct SettingsGroup<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.35))
                .tracking(0.8)
                .padding(.leading, 4)
                .padding(.bottom, 5)

            VStack(spacing: 0) {
                content
            }
            .background(groupBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.18), location: 0),
                                .init(color: .white.opacity(0.05), location: 1),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
        }
    }

    private var groupBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.06))
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.06), location: 0),
                            .init(color: .clear, location: 0.5),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }
}

// MARK: - Setting Row

struct SettingRow<Content: View>: View {
    let label: String
    let icon: String
    let iconColor: Color
    let content: Content

    init(label: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.label = label
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(iconColor.opacity(0.85))
                        .frame(width: 18, height: 18)
                        .shadow(color: iconColor.opacity(0.5), radius: 2.5, x: 0, y: 1)
                    Image(systemName: icon)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text(label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .tracking(0.1)
            }
            content
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Row Divider

struct RowDivider: View {
    var body: some View {
        Rectangle()
            .fill(.white.opacity(0.07))
            .frame(height: 0.5)
            .padding(.leading, 40)
    }
}

// MARK: - Opacity Slider

struct OpacitySlider: View {
    @Binding var value: Double

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "circle.dotted")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.35))
            Slider(value: $value, in: 0.3...1.0)
                .tint(.white.opacity(0.65))
            Image(systemName: "circle.fill")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.65))
        }
    }
}

// MARK: - Segment Picker

struct SegmentPicker<T: SettingOption>: View {
    let options: [T]
    @Binding var selection: T
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { option in
                let selected = selection == option
                Button {
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                        selection = option
                    }
                } label: {
                    Text(option.label)
                        .font(.system(size: 11, weight: selected ? .semibold : .regular, design: .rounded))
                        .foregroundStyle(selected ? .white : .white.opacity(0.4))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background {
                            if selected {
                                Capsule()
                                    .fill(.white.opacity(0.22))
                                    .matchedGeometryEffect(id: "pill", in: ns)
                            }
                        }
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.22, dampingFraction: 0.82), value: selected)
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(.white.opacity(0.08))
                .overlay(Capsule().strokeBorder(.white.opacity(0.14), lineWidth: 0.5))
        )
    }
}

import WidgetScreenCore
import SwiftUI
import AppKit

struct SettingsPanel: View {
    @Binding var showSettings: Bool
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            panelHeader

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    SettingsGroup(title: "Location") {
                        SettingRow(label: "Source", icon: "location") {
                            HStack(spacing: 10) {
                                Text(settings.locationMode == .auto ? "Automatic" : currentLocationLabel)
                                    .font(WidgetTypography.settingsValue)
                                    .foregroundStyle(WidgetPalette.secondaryText)
                                    .lineLimit(1)
                                Spacer(minLength: 8)
                                Button("Edit") {
                                    NSApp.sendAction(#selector(AppDelegate.openPreferences), to: nil, from: nil)
                                }
                                .buttonStyle(.plain)
                                .font(WidgetTypography.settingsControl)
                                .foregroundStyle(WidgetPalette.primaryText)
                            }
                        }
                    }

                    SettingsGroup(title: "Units") {
                        SettingRow(label: "Temperature", icon: "thermometer.medium") {
                            SegmentPicker(options: Array(TempUnit.allCases), selection: $settings.tempUnit)
                        }
                        RowDivider()
                        SettingRow(label: "Wind Speed", icon: "wind") {
                            SegmentPicker(options: Array(WindUnit.allCases), selection: $settings.windUnit)
                        }
                        RowDivider()
                        SettingRow(label: "Time Format", icon: "clock") {
                            SegmentPicker(options: Array(TimeFormat.allCases), selection: $settings.timeFormat)
                        }
                    }

                    SettingsGroup(title: "Widget") {
                        SettingRow(label: "Size", icon: "rectangle") {
                            SegmentPicker(options: Array(WidgetSize.allCases), selection: $settings.widgetSize)
                        }
                        RowDivider()
                        SettingRow(label: "Position", icon: "arrow.up.left.and.arrow.down.right") {
                            SegmentPicker(options: Array(WidgetPosition.allCases), selection: $settings.position)
                        }
                        RowDivider()
                        SettingRow(label: "Refresh", icon: "arrow.clockwise") {
                            SegmentPicker(options: Array(RefreshInterval.allCases), selection: $settings.refreshInterval)
                        }
                    }

                    SettingsGroup(title: "Appearance") {
                        SettingRow(label: "Glass", icon: "square.3.layers.3d") {
                            SegmentPicker(options: Array(GlassStyle.allCases), selection: $settings.glassStyle)
                        }
                        if settings.glassStyle == .frosted {
                            RowDivider()
                            SettingRow(label: "Opacity", icon: "circle.lefthalf.filled") {
                                OpacitySlider(value: $settings.frostedOpacity)
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }

            panelFooter
        }
    }

    private var currentLocationLabel: String {
        settings.manualCityName.isEmpty ? "Custom City" : settings.manualCityName
    }

    private var panelHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Widget Settings")
                    .font(WidgetTypography.settingsTitle)
                    .foregroundStyle(WidgetPalette.primaryText)

                Text("Black-and-white controls with live updates.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(WidgetPalette.tertiaryText)
            }

            Spacer()

            Button {
                withAnimation(Motion.spring(Motion.defaultSpring, reduceMotion: reduceMotion)) {
                    showSettings = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(WidgetPalette.primaryText)
                    .frame(width: 28, height: 28)
                    .background(MonochromeInsetBackground(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close settings")
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 14)
    }

    private var panelFooter: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(WidgetPalette.divider)
                .frame(height: 1)
                .padding(.horizontal, 14)

            HStack {
                Text("Open-Meteo weather data")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(WidgetPalette.quaternaryText)

                Spacer()

                Button("All Settings") {
                    NSApp.sendAction(#selector(AppDelegate.openPreferences), to: nil, from: nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(WidgetPalette.secondaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

struct SettingsGroup<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(WidgetTypography.settingsSection)
                .foregroundStyle(WidgetPalette.quaternaryText)
                .tracking(0.8)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content
            }
            .padding(.vertical, 2)
            .background(MonochromePanelBackground(cornerRadius: 18))
        }
    }
}

struct SettingRow<Content: View>: View {
    let label: String
    let icon: String
    let content: Content

    init(label: String, icon: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.icon = icon
        self.content = content()
    }

    init(label: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.label = label
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WidgetPalette.secondaryText)
                    .frame(width: 18, height: 18)

                Text(label)
                    .font(WidgetTypography.settingsLabel)
                    .foregroundStyle(WidgetPalette.primaryText)
            }

            content
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

struct RowDivider: View {
    var body: some View {
        Rectangle()
            .fill(WidgetPalette.divider)
            .frame(height: 1)
            .padding(.leading, 40)
            .padding(.trailing, 14)
    }
}

struct OpacitySlider: View {
    @Binding var value: Double

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "circle")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(WidgetPalette.tertiaryText)

            Slider(value: $value, in: 0.3...1.0)
                .tint(WidgetPalette.primaryText)

            Text("\(Int(value * 100))%")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(WidgetPalette.secondaryText)
                .frame(width: 36, alignment: .trailing)
        }
    }
}

struct SegmentPicker<T: SettingOption>: View {
    let options: [T]
    @Binding var selection: T
    @Namespace private var ns
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                let selected = selection == option

                Button {
                    withAnimation(Motion.spring(Motion.quickSpring, reduceMotion: reduceMotion)) {
                        selection = option
                    }
                } label: {
                    Text(option.label)
                        .font(.system(size: 11, weight: selected ? .bold : .medium))
                        .foregroundStyle(selected ? WidgetPalette.primaryText : WidgetPalette.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            if selected {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(WidgetPalette.selectedFill)
                                    .matchedGeometryEffect(id: "segment", in: ns)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(MonochromeInsetBackground(cornerRadius: 12))
    }
}

import SwiftUI

// MARK: - Settings Panel

struct SettingsPanel: View {
    @Binding var showSettings: Bool
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header
            HStack(alignment: .center) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                Text("Settings")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        showSettings = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.65))
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(.white.opacity(0.12)))
                        .overlay(Circle().strokeBorder(.white.opacity(0.2), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 12)

            separator

            VStack(alignment: .leading, spacing: 0) {
                settingsRow(label: "TEMPERATURE", icon: "thermometer.medium") {
                    GlassSegmentPicker(options: Array(TempUnit.allCases), selection: $settings.tempUnit)
                }
                settingsRow(label: "WIND SPEED", icon: "wind") {
                    GlassSegmentPicker(options: Array(WindUnit.allCases), selection: $settings.windUnit)
                }

                separator.padding(.vertical, 4)

                settingsRow(label: "POSITION", icon: "arrow.up.left.and.arrow.down.right") {
                    GlassSegmentPicker(options: Array(WidgetPosition.allCases), selection: $settings.position)
                }
                settingsRow(label: "GLASS DEPTH", icon: "circle.hexagongrid") {
                    GlassSegmentPicker(options: Array(GlassIntensity.allCases), selection: $settings.glassIntensity)
                }
                settingsRow(label: "AUTO-REFRESH", icon: "arrow.clockwise") {
                    GlassSegmentPicker(options: Array(RefreshInterval.allCases), selection: $settings.refreshInterval)
                }
            }
            .padding(.top, 4)

            Spacer()

            Text("WeatherWidget · Open Meteo")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.2))
                .frame(maxWidth: .infinity)
                .padding(.bottom, 14)
        }
    }

    private var separator: some View {
        Rectangle()
            .fill(.white.opacity(0.08))
            .frame(height: 0.5)
            .padding(.horizontal, 12)
    }

    private func settingsRow<Content: View>(
        label: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(0.6)
            }
            content()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 9)
    }
}

// MARK: - Segment Picker

struct GlassSegmentPicker<T: SettingOption>: View {
    let options: [T]
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { option in
                let isSelected = selection == option
                Button(option.label) {
                    withAnimation(.easeInOut(duration: 0.15)) { selection = option }
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(isSelected ? Color.white.opacity(0.22) : Color.clear)
                )
                .foregroundColor(isSelected ? .white : .white.opacity(0.4))
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular, design: .rounded))
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: isSelected)
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(.white.opacity(0.08))
                .overlay(Capsule().strokeBorder(.white.opacity(0.15), lineWidth: 0.5))
        )
    }
}

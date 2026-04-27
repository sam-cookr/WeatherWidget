import WidgetScreenCore
import SwiftUI

/// Scaled-down live preview of the weather widget that reflects SettingsStore changes.
/// Used in the Preferences window. Uses fixed sample data — does not make network requests.
struct LivePreviewPane: View {
    @EnvironmentObject var settings: SettingsStore

    private var previewVM: WeatherViewModel {
        WeatherViewModel(settings: settings, previewData: WeatherViewModel.sample())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.on.rectangle")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(WidgetPalette.secondaryText)

                    Text("Live Preview")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(WidgetPalette.primaryText)
                        .textCase(.uppercase)
                        .tracking(0.4)
                }

                Text("\(settings.widgetSize.fullLabel) · \(settings.glassStyle.label)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WidgetPalette.tertiaryText)
            }

            GeometryReader { geo in
                let widgetSize = settings.widgetSize.windowSize
                let scale = min(
                    (geo.size.width - 28) / widgetSize.width,
                    (geo.size.height - 36) / widgetSize.height,
                    0.76
                )

                ZStack(alignment: previewAlignment) {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.026))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                        )

                    WeatherView(viewModel: previewVM, isMiniPreview: true)
                        .environmentObject(settings)
                        .scaleEffect(scale, anchor: .top)
                        .frame(width: widgetSize.width * scale, height: widgetSize.height * scale)
                        .padding(14)
                }
            }
            .frame(maxHeight: .infinity)

            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                Text("Settings update instantly.")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(WidgetPalette.tertiaryText)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.42)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.105), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.28), radius: 24, x: 0, y: 18)
        )
    }

    private var previewAlignment: Alignment {
        switch settings.position {
        case .topLeft:
            return .topLeading
        case .topRight:
            return .topTrailing
        case .bottomLeft:
            return .bottomLeading
        case .bottomRight:
            return .bottomTrailing
        }
    }
}

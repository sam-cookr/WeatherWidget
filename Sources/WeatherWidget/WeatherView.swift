import WidgetScreenCore
import SwiftUI
import AppKit

// MARK: - Root View

struct WeatherView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @EnvironmentObject var settings: SettingsStore
    @State private var showSettings = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    var isMiniPreview = false

    var body: some View {
        let size = settings.widgetSize.windowSize
        Group {
            if isMiniPreview {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                    contentGroup
                }
            } else if settings.glassStyle == .clear {
                LiquidGlassBackground(variant: 11, cornerRadius: 28) {
                    contentGroup
                        .environmentObject(settings)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color(white: 0.5, opacity: 0.18), lineWidth: 2)
                        .blur(radius: 2)
                )
            } else {
                ZStack {
                    FrostedGlassBackground()
                        .opacity(settings.frostedOpacity)
                    contentGroup
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(.black.opacity(0.50), lineWidth: 5)
                        .blur(radius: 3)
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(.black.opacity(0.40), lineWidth: 1.0)
                    RoundedRectangle(cornerRadius: 27, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 0.5)
                        .padding(1)
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.5),  radius: 24, x: 0, y: 12)
        .shadow(color: .black.opacity(0.20), radius: 3,  x: 0, y: 1)
    }

    @ViewBuilder
    private var contentGroup: some View {
        Group {
            if showSettings {
                SettingsPanel(showSettings: $showSettings)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .trailing).combined(with: .opacity)
                    ))
            } else if viewModel.isLoading && viewModel.weather == nil {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.4)
                    .transition(.opacity)
            } else if let weather = viewModel.weather {
                WeatherContent(weather: weather, viewModel: viewModel, showSettings: $showSettings, isMiniPreview: isMiniPreview)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    ))
            } else if let err = viewModel.errorMessage {
                ErrorView(message: err, viewModel: viewModel, showSettings: $showSettings)
                    .transition(.opacity)
            }
        }
        .animation(Motion.spring(Motion.defaultSpring, reduceMotion: reduceMotion), value: showSettings)
    }
}

// MARK: - Weather Content

struct WeatherContent: View {
    let weather: WeatherData
    @ObservedObject var viewModel: WeatherViewModel
    @Binding var showSettings: Bool
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    var isMiniPreview = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            topBar
                .padding(.horizontal, 18)
                .padding(.top, 18)

            heroSection
                .padding(.horizontal, 18)
                .padding(.top, settings.widgetSize == .compact ? 16 : 14)

            if settings.widgetSize != .compact {
                Spacer(minLength: 18)
                detailPanel
                Spacer().frame(height: 16)

                if settings.widgetSize == .large && !weather.forecast.isEmpty {
                    forecastRow
                    Spacer().frame(height: 16)
                }
            } else {
                Spacer()
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(WidgetPalette.tertiaryText)

                Text(weather.city)
                    .font(WidgetTypography.widgetTitle)
                    .foregroundStyle(WidgetPalette.primaryText)
                    .lineLimit(1)

                if viewModel.stalenessLevel != .none {
                    Circle()
                        .fill(WidgetPalette.secondaryText.opacity(0.7))
                        .frame(width: 4, height: 4)
                        .accessibilityLabel("Weather data is stale")
                }
            }

            Spacer()

            if !isMiniPreview {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.55)
                        .tint(WidgetPalette.secondaryText)
                        .frame(width: 24, height: 24)
                } else {
                    Button {
                        withAnimation(Motion.spring(Motion.defaultSpring, reduceMotion: reduceMotion)) {
                            showSettings = true
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(WidgetPalette.secondaryText)
                            .frame(width: 28, height: 28)
                            .background(MonochromeInsetBackground(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open settings")
                    .accessibilityHint("Opens the quick settings panel")
                }
            }
        }
    }

    private var heroSection: some View {
        HStack(alignment: .bottom, spacing: 14) {
            Image(systemName: WeatherViewModel.sfSymbol(for: weather.conditionCode))
                .font(.system(size: settings.widgetSize == .compact ? 34 : 32, weight: .medium))
                .symbolRenderingMode(.multicolor)
                .shadow(color: .black.opacity(0.22), radius: 3, x: 0, y: 2)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 1) {
                    Text("\(Int(weather.temperature.rounded()))")
                        .font(WidgetTypography.widgetHero)
                        .foregroundStyle(viewModel.stalenessLevel == .veryStale
                            ? WidgetPalette.tertiaryText : WidgetPalette.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text("°")
                        .font(WidgetTypography.widgetDegree)
                        .foregroundStyle(WidgetPalette.secondaryText)
                        .padding(.top, 12)
                }

                Text(weather.condition)
                    .font(WidgetTypography.widgetCondition)
                    .foregroundStyle(WidgetPalette.secondaryText)
                    .lineLimit(1)

                Text(weather.highLowString)
                    .font(WidgetTypography.widgetSubheadline)
                    .foregroundStyle(WidgetPalette.tertiaryText)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Detail panel

    @ViewBuilder
    private var detailPanel: some View {
        let cells = visibleCellData
        if !cells.isEmpty {
            let chunks = stride(from: 0, to: cells.count, by: 3).map {
                Array(cells[$0..<min($0 + 3, cells.count)])
            }
            VStack(spacing: 0) {
                ForEach(Array(chunks.enumerated()), id: \.offset) { idx, chunk in
                    if idx > 0 { rowDivider }
                    dynamicDetailRow(chunk)
                }
                rowDivider
                HStack(spacing: 0) {
                    sunriseSunsetCell(icon: "sunrise.fill",
                                      time: formatSunTime(weather.sunriseISO, use24h: settings.timeFormat.use24h))
                    Rectangle()
                        .fill(.white.opacity(0.08))
                        .frame(width: 0.5, height: 20)
                    sunriseSunsetCell(icon: "sunset.fill",
                                      time: formatSunTime(weather.sunsetISO, use24h: settings.timeFormat.use24h))
                }
                .padding(.vertical, 12)
            }
            .background(unifiedPanelBackground)
            .padding(.horizontal, 12)
        }
    }

    private var visibleCellData: [(DetailCell, String)] {
        let all: [(DetailCell, String)] = [
            (.feelsLike, weather.feelsLikeString),
            (.humidity,  "\(weather.humidity)%"),
            (.wind,      weather.windString),
            (.uvIndex,   weather.uvString),
            (.rain,      weather.precipString),
            (.dewPoint,  weather.dewPointString),
        ]
        return all.filter { settings.visibleDetailCells.contains($0.0) }
    }

    // MARK: - 3-day forecast row

    private var forecastRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(weather.forecast.enumerated()), id: \.offset) { idx, day in
                if idx > 0 {
                    Rectangle()
                        .fill(.white.opacity(0.08))
                        .frame(width: 0.5, height: 44)
                }
                ForecastDayView(day: day)
            }
        }
        .padding(.vertical, 12)
        .background(unifiedPanelBackground)
        .padding(.horizontal, 12)
    }

    // MARK: - Sub-views

    private func dynamicDetailRow(_ items: [(DetailCell, String)]) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if index > 0 {
                    Rectangle()
                        .fill(.white.opacity(0.08))
                        .frame(width: 0.5, height: 26)
                }
                DetailCellView(icon: item.0.icon, label: item.0.shortLabel, value: item.1)
            }
        }
        .padding(.vertical, 12)
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.07))
            .frame(height: 0.5)
            .padding(.horizontal, 12)
    }

    private func sunriseSunsetCell(icon: String, time: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .symbolRenderingMode(.multicolor)
            Text(time)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(WidgetPalette.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var unifiedPanelBackground: some View {
        MonochromePanelBackground(cornerRadius: 18)
    }
}

// MARK: - Detail Cell View

struct DetailCellView: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(WidgetPalette.tertiaryText)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(WidgetPalette.primaryText)
            Text(label)
                .font(WidgetTypography.widgetCaption)
                .foregroundStyle(WidgetPalette.quaternaryText)
                .textCase(.uppercase)
                .tracking(0.4)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Forecast Day View

private struct ForecastDayView: View {
    let day: ForecastDay

    var body: some View {
        VStack(spacing: 4) {
            Text(day.dayLabel)
                .font(WidgetTypography.widgetCaption)
                .foregroundStyle(WidgetPalette.quaternaryText)
                .textCase(.uppercase)
                .tracking(0.3)
            Image(systemName: WeatherViewModel.sfSymbol(for: day.conditionCode))
                .font(.system(size: 18))
                .symbolRenderingMode(.multicolor)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            Text("H:\(Int(day.high.rounded()))°")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(WidgetPalette.primaryText)
            Text("L:\(Int(day.low.rounded()))°")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(WidgetPalette.tertiaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    @ObservedObject var viewModel: WeatherViewModel
    @Binding var showSettings: Bool
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.wifi")
                .font(.system(size: 36))
                .foregroundStyle(WidgetPalette.tertiaryText)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(WidgetPalette.secondaryText)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await viewModel.fetch() }
            }
            .buttonStyle(GlassButtonStyle())
            Button {
                withAnimation(Motion.spring(Motion.defaultSpring, reduceMotion: reduceMotion)) { showSettings = true }
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 13))
                    .foregroundStyle(WidgetPalette.secondaryText)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(24)
    }
}

// MARK: - Glass Button Style

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(WidgetPalette.primaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(configuration.isPressed ? WidgetPalette.pressedFill : WidgetPalette.surfaceSecondary)
            )
            .overlay(Capsule().strokeBorder(WidgetPalette.borderPrimary, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(Motion.fastSpring, value: configuration.isPressed)
    }
}

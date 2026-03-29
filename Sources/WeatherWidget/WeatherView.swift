import SwiftUI
import AppKit

// MARK: - Lock-Screen Glass Background

/// Wraps `NSGlassEffectView` (macOS 15+) with an `NSVisualEffectView` fallback.
/// This provides native compositor-level transparency without Screen Recording permission.
private struct LockScreenGlassView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.isOpaque = false

        if let GlassClass = NSClassFromString("NSGlassEffectView") as? NSView.Type {
            let glass = GlassClass.init(frame: .zero)
            glass.autoresizingMask = [.width, .height]
            container.addSubview(glass)
        } else {
            let blur = NSVisualEffectView(frame: .zero)
            blur.autoresizingMask = [.width, .height]
            blur.material    = .hudWindow
            blur.blendingMode = .behindWindow
            blur.state       = .active
            container.addSubview(blur)
        }
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

/// Frosted glass background — native compositor blur with dark overlay for readability.
private struct FrostedGlassBackground: View {
    var body: some View {
        ZStack {
            LockScreenGlassView()
            Color.black.opacity(0.22)
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.09), location: 0),
                    .init(color: .clear, location: 0.22),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

/// Clear glass background — nearly transparent with specular highlights only.
/// No blur layer; the wallpaper/lock screen shows through with just a thin tint.
private struct ClearGlassBackground: View {
    var body: some View {
        ZStack {
            // Very thin dark tint — just enough contrast for white text
            Color.black.opacity(0.08)

            // Subtle body gradient — slightly darker at bottom aids readability
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.04), location: 0),
                    .init(color: .black.opacity(0.14), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Primary specular — bright band near top simulates light hitting glass
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.38), location: 0),
                    .init(color: .white.opacity(0.14), location: 0.07),
                    .init(color: .clear,               location: 0.18),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Prismatic edge shimmer — very thin rainbow tint at the top lip
            LinearGradient(
                stops: [
                    .init(color: Color(hue: 0.58, saturation: 0.35, brightness: 1).opacity(0.10), location: 0.00),
                    .init(color: Color(hue: 0.38, saturation: 0.25, brightness: 1).opacity(0.07), location: 0.025),
                    .init(color: .clear,                                                           location: 0.055),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Bottom inner reflection — faint upward lift from the base edge
            LinearGradient(
                stops: [
                    .init(color: .clear,               location: 0.80),
                    .init(color: .white.opacity(0.06), location: 1.00),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

/// Selects between frosted and clear glass based on the current setting.
private struct GlassBackground: View {
    let style: GlassStyle

    var body: some View {
        if style == .clear {
            ClearGlassBackground()
        } else {
            FrostedGlassBackground()
        }
    }
}

// MARK: - Root View

struct WeatherView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @EnvironmentObject var settings: SettingsStore
    @State private var showSettings = false

    var body: some View {
        ZStack {
            GlassBackground(style: settings.glassStyle)

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
                    WeatherContent(weather: weather, viewModel: viewModel, showSettings: $showSettings)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal:   .move(edge: .leading).combined(with: .opacity)
                        ))
                } else if let err = viewModel.errorMessage {
                    ErrorView(message: err, viewModel: viewModel, showSettings: $showSettings)
                        .transition(.opacity)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showSettings)

            // Specular edge — angular gradient simulates glass rim lighting
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    AngularGradient(
                        stops: [
                            .init(color: .white.opacity(0.45), location: 0.00),
                            .init(color: .white.opacity(0.18), location: 0.10),
                            .init(color: .white.opacity(0.05), location: 0.30),
                            .init(color: .white.opacity(0.01), location: 0.50),
                            .init(color: .white.opacity(0.05), location: 0.70),
                            .init(color: .white.opacity(0.18), location: 0.90),
                            .init(color: .white.opacity(0.45), location: 1.00),
                        ],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    lineWidth: 1.0
                )
        }
        .frame(width: 280, height: 380)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.5),  radius: 24, x: 0, y: 12)
        .shadow(color: .black.opacity(0.20), radius: 3,  x: 0, y: 1)
    }
}

// MARK: - Weather Content

struct WeatherContent: View {
    let weather: WeatherData
    @ObservedObject var viewModel: WeatherViewModel
    @Binding var showSettings: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Location row ──────────────────────────────────────────────────
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                Text(weather.city)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.5)
                        .tint(.white.opacity(0.5))
                        .frame(width: 16, height: 16)
                } else {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showSettings = true
                        }
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)

            // ── Temperature + Condition ───────────────────────────────────────
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: WeatherViewModel.sfSymbol(for: weather.conditionCode))
                    .font(.system(size: 38))
                    .symbolRenderingMode(.multicolor)
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .top, spacing: 0) {
                        Text("\(Int(weather.temperature.rounded()))")
                            .font(.system(size: 44, weight: .thin, design: .rounded))
                            .foregroundColor(.white)
                        Text("°")
                            .font(.system(size: 22, weight: .light))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 5)
                    }
                    Text(weather.condition)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.65))
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)

            Text(weather.highLowString)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 18)
                .padding(.top, 4)

            Spacer(minLength: 12)

            // ── Detail rows ───────────────────────────────────────────────────
            detailRow([
                ("thermometer.medium", "Feels Like", weather.feelsLikeString),
                ("humidity",           "Humidity",   "\(weather.humidity)%"),
                ("wind",               "Wind",       weather.windString),
            ])

            Spacer().frame(height: 8)

            detailRow([
                ("sun.max.fill",          "UV Index", weather.uvString),
                ("cloud.rain",            "Rain",     weather.precipString),
                ("thermometer.snowflake", "Dew Pt",   weather.dewPointString),
            ])

            Spacer().frame(height: 8)

            // ── Sunrise / Sunset ──────────────────────────────────────────────
            HStack(spacing: 0) {
                sunriseSunsetCell(icon: "sunrise.fill", time: weather.sunrise)
                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 0.5, height: 20)
                sunriseSunsetCell(icon: "sunset.fill", time: weather.sunset)
            }
            .padding(.vertical, 10)
            .background(pillBackground)
            .padding(.horizontal, 12)

            Spacer().frame(height: 14)
        }
    }

    // MARK: - Sub-views

    private func detailRow(_ items: [(String, String, String)]) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if index > 0 {
                    Rectangle()
                        .fill(.white.opacity(0.08))
                        .frame(width: 0.5, height: 26)
                }
                DetailCell(icon: item.0, label: item.1, value: item.2)
            }
        }
        .padding(.vertical, 10)
        .background(pillBackground)
        .padding(.horizontal, 12)
    }

    private func sunriseSunsetCell(icon: String, time: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .symbolRenderingMode(.multicolor)
            Text(time)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
    }

    private var pillBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.10), location: 0),
                            .init(color: .clear, location: 0.5),
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.28), location: 0),
                            .init(color: .white.opacity(0.08), location: 1),
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
    }
}

// MARK: - Detail Cell

struct DetailCell: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(.white.opacity(0.55))
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
                .textCase(.uppercase)
                .tracking(0.4)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    @ObservedObject var viewModel: WeatherViewModel
    @Binding var showSettings: Bool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.wifi")
                .font(.system(size: 36))
                .foregroundColor(.white.opacity(0.5))
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await viewModel.fetch() }
            }
            .buttonStyle(GlassButtonStyle())
            Button {
                withAnimation(.spring(response: 0.35)) { showSettings = true }
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.35))
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
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(.white.opacity(configuration.isPressed ? 0.18 : 0.10)))
            .overlay(Capsule().strokeBorder(.white.opacity(0.22), lineWidth: 0.5))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

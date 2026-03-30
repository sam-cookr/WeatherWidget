import SwiftUI
import AppKit

// MARK: - Lock-Screen Glass Background

/// Wraps `NSGlassEffectView` (macOS 15+) with an `NSVisualEffectView` fallback.
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

/// Frosted glass background — raw NSGlassEffectView, no overlay.
private struct FrostedGlassBackground: View {
    var body: some View {
        LockScreenGlassView()
    }
}

/// Clear glass background — fully transparent.
private struct ClearGlassBackground: View {
    var body: some View {
        Color.clear
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

            // Edge refraction — varies by glass style
            if settings.glassStyle == .clear {
                // Soft prismatic halo
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        AngularGradient(
                            stops: [
                                .init(color: Color(red: 0.70, green: 0.88, blue: 1.00).opacity(0.45), location: 0.00),
                                .init(color: Color(red: 0.88, green: 0.68, blue: 1.00).opacity(0.35), location: 0.25),
                                .init(color: Color(red: 1.00, green: 0.85, blue: 0.62).opacity(0.25), location: 0.50),
                                .init(color: Color(red: 0.68, green: 1.00, blue: 0.85).opacity(0.35), location: 0.75),
                                .init(color: Color(red: 0.70, green: 0.88, blue: 1.00).opacity(0.45), location: 1.00),
                            ],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        lineWidth: 5
                    )
                    .blur(radius: 3)
                // Crisp prismatic outer rim
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        AngularGradient(
                            stops: [
                                .init(color: .white.opacity(0.85),                                       location: 0.00),
                                .init(color: Color(red: 0.62, green: 0.88, blue: 1.00).opacity(0.65),   location: 0.08),
                                .init(color: Color(red: 0.82, green: 0.62, blue: 1.00).opacity(0.45),   location: 0.20),
                                .init(color: Color(red: 1.00, green: 0.82, blue: 0.58).opacity(0.28),   location: 0.35),
                                .init(color: .white.opacity(0.04),                                       location: 0.50),
                                .init(color: Color(red: 0.58, green: 0.92, blue: 1.00).opacity(0.32),   location: 0.65),
                                .init(color: Color(red: 0.90, green: 0.65, blue: 1.00).opacity(0.50),   location: 0.82),
                                .init(color: .white.opacity(0.85),                                       location: 1.00),
                            ],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        lineWidth: 1.0
                    )
                // Inner top-arc specular
                RoundedRectangle(cornerRadius: 27, style: .continuous)
                    .stroke(
                        AngularGradient(
                            stops: [
                                .init(color: .white.opacity(0.55), location: 0.00),
                                .init(color: .white.opacity(0.18), location: 0.12),
                                .init(color: .clear,               location: 0.26),
                                .init(color: .clear,               location: 0.74),
                                .init(color: .white.opacity(0.14), location: 0.88),
                                .init(color: .white.opacity(0.42), location: 1.00),
                            ],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        lineWidth: 0.75
                    )
                    .padding(1.5)
                // Deep inset rim
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .stroke(.white.opacity(0.07), lineWidth: 0.5)
                    .padding(3)
            } else if settings.glassStyle == .frosted {
                // Soft dark halo — broad refraction shadow
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.black.opacity(0.50), lineWidth: 5)
                    .blur(radius: 3)
                // Crisp dark outer rim — the glass edge
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.black.opacity(0.40), lineWidth: 1.0)
                // Hair-thin inner highlight
                RoundedRectangle(cornerRadius: 27, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 0.5)
                    .padding(1)
            }
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
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.70))
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)

            Text(weather.highLowString)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .padding(.horizontal, 18)
                .padding(.top, 4)

            Spacer(minLength: 12)

            // ── Detail panel — all rows on one shared background ──────────────
            VStack(spacing: 0) {
                detailRow([
                    ("thermometer.medium", "Feels Like", weather.feelsLikeString),
                    ("humidity",           "Humidity",   "\(weather.humidity)%"),
                    ("wind",               "Wind",       weather.windString),
                ])
                rowDivider
                detailRow([
                    ("sun.max.fill",          "UV Index", weather.uvString),
                    ("cloud.rain",            "Rain",     weather.precipString),
                    ("thermometer.snowflake", "Dew Pt",   weather.dewPointString),
                ])
                rowDivider
                HStack(spacing: 0) {
                    sunriseSunsetCell(icon: "sunrise.fill", time: weather.sunrise)
                    Rectangle()
                        .fill(.white.opacity(0.08))
                        .frame(width: 0.5, height: 20)
                    sunriseSunsetCell(icon: "sunset.fill", time: weather.sunset)
                }
                .padding(.vertical, 10)
            }
            .background(unifiedPanelBackground)
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
                .font(.system(size: 13))
                .symbolRenderingMode(.multicolor)
            Text(time)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
    }

    private var unifiedPanelBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.07))
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.08), location: 0),
                            .init(color: .clear, location: 0.4),
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.22), location: 0),
                            .init(color: .white.opacity(0.07), location: 1),
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
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white.opacity(0.45))
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

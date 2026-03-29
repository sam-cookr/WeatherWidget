import SwiftUI
import AppKit

// MARK: - NSVisualEffectView wrapper (real compositor transparency)

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material     = material
        v.blendingMode = blendingMode
        v.state        = .active
        v.isEmphasized = false
        return v
    }
    func updateNSView(_ v: NSVisualEffectView, context: Context) {
        v.material     = material
        v.blendingMode = blendingMode
    }
}

// MARK: - Runtime Glass Adapter

struct AdaptiveGlassView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var cornerRadius: CGFloat = 28

    func makeNSView(context: Context) -> NSView {
        let host = NSView()
        host.wantsLayer = true
        host.layer?.isOpaque = false
        host.layer?.cornerCurve = .continuous
        host.layer?.cornerRadius = cornerRadius
        host.layer?.masksToBounds = true

        if let glassClass = NSClassFromString("NSGlassEffectView") as? NSView.Type {
            let glass = glassClass.init(frame: .zero)
            glass.frame = host.bounds
            glass.autoresizingMask = [.width, .height]
            applyRuntimeGlassSettings(to: glass)
            host.addSubview(glass)
        } else {
            let fallback = NSVisualEffectView(frame: host.bounds)
            fallback.autoresizingMask = [.width, .height]
            fallback.material = material
            fallback.blendingMode = blendingMode
            fallback.state = .active
            fallback.isEmphasized = false
            host.addSubview(fallback)
        }
        return host
    }

    func updateNSView(_ host: NSView, context: Context) {
        guard let glassOrFallback = host.subviews.first else { return }
        applyRuntimeGlassSettings(to: glassOrFallback)
        if let fallback = glassOrFallback as? NSVisualEffectView {
            fallback.material = material
            fallback.blendingMode = blendingMode
        }
        host.layer?.cornerRadius = cornerRadius
        host.layer?.masksToBounds = true
    }

    private func applyRuntimeGlassSettings(to view: NSView) {
        let setState = NSSelectorFromString("setState:")
        if view.responds(to: setState) {
            (view as NSObject).setValue(NSVisualEffectView.State.active.rawValue, forKey: "state")
        }
        let setBlending = NSSelectorFromString("setBlendingMode:")
        if view.responds(to: setBlending) {
            (view as NSObject).setValue(blendingMode.rawValue, forKey: "blendingMode")
        }
        let setMaterial = NSSelectorFromString("setMaterial:")
        if view.responds(to: setMaterial) {
            (view as NSObject).setValue(material.rawValue, forKey: "material")
        }
        let setEmphasized = NSSelectorFromString("setEmphasized:")
        if view.responds(to: setEmphasized) {
            (view as NSObject).setValue(false, forKey: "emphasized")
        }

        // NSGlassEffectView runtime tuning (only when supported by selector).
        let setStyle = NSSelectorFromString("setStyle:")
        if view.responds(to: setStyle) {
            (view as NSObject).setValue(1, forKey: "style")
        }
        let setVariant = NSSelectorFromString("setVariant:")
        if view.responds(to: setVariant) {
            (view as NSObject).setValue(1, forKey: "variant")
        }
        let setScrimState = NSSelectorFromString("set_scrimState:")
        if view.responds(to: setScrimState) {
            (view as NSObject).setValue(0, forKey: "scrimState")
        }
        let setSubduedState = NSSelectorFromString("set_subduedState:")
        if view.responds(to: setSubduedState) {
            (view as NSObject).setValue(0, forKey: "subduedState")
        }
        let setContentLensing = NSSelectorFromString("set_contentLensing:")
        if view.responds(to: setContentLensing) {
            (view as NSObject).setValue(1, forKey: "contentLensing")
        }
        let setReducedShadow = NSSelectorFromString("set_useReducedShadowRadius:")
        if view.responds(to: setReducedShadow) {
            (view as NSObject).setValue(true, forKey: "useReducedShadowRadius")
        }
        let setTint = NSSelectorFromString("setTintColor:")
        if view.responds(to: setTint) {
            (view as NSObject).setValue(NSColor.white.withAlphaComponent(0.01), forKey: "tintColor")
        }
        let setCornerRadius = NSSelectorFromString("setCornerRadius:")
        if view.responds(to: setCornerRadius) {
            (view as NSObject).setValue(cornerRadius, forKey: "cornerRadius")
        }
        let setClipsToBounds = NSSelectorFromString("setClipsToBounds:")
        if view.responds(to: setClipsToBounds) {
            (view as NSObject).setValue(true, forKey: "clipsToBounds")
        }
    }
}

struct LockScreenGlassProbeView: View {
    var body: some View {
        ZStack {
            LiquidGlassBackground(intensity: 1.0)

            VStack(spacing: 8) {
                Text("Glass Probe")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
                Text("Lock-screen level + glass only")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.62))
            }
        }
        .frame(width: 280, height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.24), lineWidth: 0.8)
        )
    }
}

// MARK: - Root View

struct WeatherView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @EnvironmentObject var settings: SettingsStore
    @State private var showSettings = false

    var body: some View {
        ZStack {
            LiquidGlassBackground(intensity: settings.glassIntensity.overlayScale)

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
                    errorView(message: err)
                        .transition(.opacity)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showSettings)

            // Liquid glass border — angular gradient simulates edge lighting
            liquidGlassBorder
        }
        .frame(width: 280, height: 380)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.45), radius: 24, x: 0, y: 10)
        .shadow(color: .black.opacity(0.18), radius: 3,  x: 0, y: 1)
    }

    private var liquidGlassBorder: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .stroke(
                AngularGradient(
                    stops: [
                        .init(color: .white.opacity(0.42), location: 0.00),
                        .init(color: .white.opacity(0.18), location: 0.10),
                        .init(color: .white.opacity(0.05), location: 0.30),
                        .init(color: .white.opacity(0.01), location: 0.50),
                        .init(color: .white.opacity(0.04), location: 0.70),
                        .init(color: .white.opacity(0.16), location: 0.90),
                        .init(color: .white.opacity(0.42), location: 1.00),
                    ],
                    center: .center,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(270)
                ),
                lineWidth: 1.0
            )
    }

    private func errorView(message: String) -> some View {
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

// MARK: - Liquid Glass Background

struct LiquidGlassBackground: View {
    var intensity: Double = 1.0

    // Map intensity to NSVisualEffectView material
    private var material: NSVisualEffectView.Material {
        if intensity < 0.8 { return .hudWindow }
        if intensity > 1.2 { return .menu }
        return .popover
    }

    var body: some View {
        ZStack {
            // ── Layer 1: Native compositor glass (no Screen Recording permission) ──
            AdaptiveGlassView(material: material, cornerRadius: 28)
                .opacity(1.0)

            // ── Layer 2: Micro-tint to match lock-screen-style glass depth ──
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.03 * intensity), location: 0.0),
                    .init(color: .white.opacity(0.01 * intensity), location: 0.25),
                    .init(color: .clear,                           location: 0.6),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // ── Layer 3: Soft caustic glow, minimal haze ──
            RadialGradient(
                stops: [
                    .init(color: .white.opacity(0.022 * intensity), location: 0.0),
                    .init(color: .white.opacity(0.004 * intensity), location: 0.4),
                    .init(color: .clear,                           location: 1.0),
                ],
                center: UnitPoint(x: 0.22, y: 0.12),
                startRadius: 0, endRadius: 260
            )

            // ── Layer 4: Primary specular — rim highlight ──
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.10 * intensity), location: 0.00),
                    .init(color: .white.opacity(0.018 * intensity), location: 0.05),
                    .init(color: .white.opacity(0.0015 * intensity), location: 0.10),
                    .init(color: .clear,                           location: 0.18),
                ],
                startPoint: .top, endPoint: .bottom
            )

            // ── Layer 5: Left rim specular ──
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.015 * intensity), location: 0.0),
                    .init(color: .white.opacity(0.003 * intensity), location: 0.04),
                    .init(color: .clear,                           location: 0.08),
                ],
                startPoint: .leading, endPoint: .trailing
            )

            // ── Layer 6: Bottom bounce light ──
            LinearGradient(
                stops: [
                    .init(color: .clear,                           location: 0.88),
                    .init(color: .white.opacity(0.006 * intensity), location: 1.00),
                ],
                startPoint: .top, endPoint: .bottom
            )
        }
    }
}

// MARK: - Weather Content

struct WeatherContent: View {
    let weather: WeatherData
    @ObservedObject var viewModel: WeatherViewModel
    @Binding var showSettings: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Location row
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

            // Icon + Temp + Condition
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: WeatherViewModel.sfSymbol(for: weather.conditionCode))
                    .font(.system(size: 38))
                    .symbolRenderingMode(.multicolor)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .top, spacing: 0) {
                        Text("\(Int(weather.temperature.rounded()))")
                            .font(.system(size: 42, weight: .thin, design: .rounded))
                            .foregroundColor(.white)
                        Text("°")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 4)
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

            detailRow([
                ("thermometer.medium", "Feels like", weather.feelsLikeString),
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

            // Sunrise / Sunset
            HStack(spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: "sunrise.fill")
                        .font(.system(size: 13))
                        .symbolRenderingMode(.multicolor)
                    Text(weather.sunrise)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(.white.opacity(0.06))
                    .frame(width: 0.5, height: 20)

                HStack(spacing: 6) {
                    Image(systemName: "sunset.fill")
                        .font(.system(size: 13))
                        .symbolRenderingMode(.multicolor)
                    Text(weather.sunset)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 10)
            .background(pillBackground)
            .padding(.horizontal, 12)

            Spacer().frame(height: 14)
        }
    }

    private func detailRow(_ items: [(String, String, String)]) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                if i > 0 {
                    Rectangle()
                        .fill(.white.opacity(0.06))
                        .frame(width: 0.5, height: 26)
                }
                DetailCell(icon: item.0, label: item.1, value: item.2)
            }
        }
        .padding(.vertical, 10)
        .background(pillBackground)
        .padding(.horizontal, 12)
    }

    private var pillBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.14), location: 0),
                            .init(color: .white.opacity(0.04), location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            // Top specular on the pill
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.22), location: 0),
                            .init(color: .clear,               location: 0.55),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.38), location: 0),
                            .init(color: .white.opacity(0.05), location: 1),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
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
                .foregroundColor(.white.opacity(0.6))
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

// MARK: - Button Style

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

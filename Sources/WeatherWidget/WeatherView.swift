import SwiftUI
import AppKit

// MARK: - Lock-Screen Glass Background

/// Container that keeps `CABackdropLayer.windowServerAware = true` and `scale = 1.0`
/// while the window lives in a SkyLight compositor space. Without this the blur goes
/// dead because the system resets those properties after the space transition.
private final class GlassContainerView: NSView {
    weak var glassView: NSView?
    var hostingView: NSHostingView<AnyView>?

    private var observedBackdropLayers: [CALayer] = []
    private var setupScheduled = false

    deinit { removeBackdropObservers() }

    override func removeFromSuperview() {
        removeBackdropObservers()
        super.removeFromSuperview()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        scheduleBackdropSetup()
    }

    override func layout() {
        super.layout()
        scheduleBackdropSetup()
    }

    func scheduleBackdropSetup() {
        guard !setupScheduled else { return }
        setupScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self else { return }
            self.setupScheduled = false
            self.configureBackdropLayers()
        }
    }

    private func configureBackdropLayers() {
        guard let glassView, let root = glassView.layer else {
            scheduleBackdropSetup()
            return
        }
        applyBackdropProperties(in: root)
        let found = collectBackdropLayers(in: root)
        removeBackdropObservers()
        observedBackdropLayers = found
        for layer in found {
            layer.addObserver(self, forKeyPath: "windowServerAware", options: [.old, .new], context: nil)
            layer.addObserver(self, forKeyPath: "scale",             options: [.old, .new], context: nil)
        }
    }

    private func applyBackdropProperties(in layer: CALayer) {
        if NSStringFromClass(type(of: layer)).contains("CABackdropLayer") {
            layer.setValue(true, forKey: "windowServerAware")
            layer.setValue(1.0,  forKey: "scale")
        }
        layer.sublayers?.forEach { applyBackdropProperties(in: $0) }
    }

    private func collectBackdropLayers(in layer: CALayer) -> [CALayer] {
        var result: [CALayer] = []
        if NSStringFromClass(type(of: layer)).contains("CABackdropLayer") { result.append(layer) }
        layer.sublayers?.forEach { result.append(contentsOf: collectBackdropLayers(in: $0)) }
        return result
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == "windowServerAware" {
            if change?[.newKey] as? Bool == false { configureBackdropLayers() }
        } else if keyPath == "scale" {
            if let layer = object as? CALayer,
               let v = (change?[.newKey] as? NSNumber)?.doubleValue, v != 1.0 {
                layer.setValue(1.0, forKey: "scale")
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    private func removeBackdropObservers() {
        for layer in observedBackdropLayers {
            layer.removeObserver(self, forKeyPath: "windowServerAware")
            layer.removeObserver(self, forKeyPath: "scale")
        }
        observedBackdropLayers.removeAll()
    }
}

// Sets NSGlassEffectView's private variant via runtime IMP dispatch (same technique as Atoll).
// Variant 11 is the Liquid Glass look Apple uses for lock-screen panels.
private typealias VariantSetterIMP = @convention(c) (AnyObject, Selector, Int) -> Void
private func applyGlassVariant(_ glass: NSView, variant: Int) {
    let sel = NSSelectorFromString("set_variant:")
    guard let m = class_getInstanceMethod(object_getClass(glass), sel) else { return }
    unsafeBitCast(method_getImplementation(m), to: VariantSetterIMP.self)(glass, sel, variant)
}

/// Frosted glass background — NSGlassEffectView as a background layer (no content embedding).
private struct FrostedGlassBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> GlassContainerView {
        let container = GlassContainerView()
        container.wantsLayer = true
        container.layer?.isOpaque = false

        if let GlassClass = NSClassFromString("NSGlassEffectView") as? NSView.Type {
            let glass = GlassClass.init(frame: .zero)
            glass.autoresizingMask = [.width, .height]
            container.addSubview(glass)
            container.glassView = glass
            container.scheduleBackdropSetup()
        } else {
            let blur = NSVisualEffectView(frame: .zero)
            blur.autoresizingMask = [.width, .height]
            blur.material     = .hudWindow
            blur.blendingMode = .behindWindow
            blur.state        = .active
            container.addSubview(blur)
        }
        return container
    }

    func updateNSView(_ nsView: GlassContainerView, context: Context) {}
}

/// Exact port of Atoll's `LiquidGlassBackground`:
/// embeds SwiftUI content as `NSGlassEffectView.contentView` via KVC so the glass
/// effect owns the content boundary and produces correct edge refraction.
/// Variant 11 is the lock-screen panel variant used by Atoll.
private struct LiquidGlassBackground<Content: View>: NSViewRepresentable {
    var variant: Int = 11
    var cornerRadius: CGFloat = 28
    var content: Content

    init(variant: Int = 11, cornerRadius: CGFloat = 28, @ViewBuilder content: () -> Content) {
        self.variant = variant
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    func makeNSView(context: Context) -> GlassContainerView {
        let container = GlassContainerView()

        if let GlassClass = NSClassFromString("NSGlassEffectView") as? NSView.Type {
            let glass = GlassClass.init(frame: .zero)
            glass.translatesAutoresizingMaskIntoConstraints = false
            glass.setValue(cornerRadius, forKey: "cornerRadius")
            applyGlassVariant(glass, variant: variant)

            let hosting = NSHostingView(rootView: AnyView(content))
            hosting.translatesAutoresizingMaskIntoConstraints = false
            glass.setValue(hosting, forKey: "contentView")

            container.addSubview(glass)
            NSLayoutConstraint.activate([
                glass.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                glass.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                glass.topAnchor.constraint(equalTo: container.topAnchor),
                glass.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])
            container.glassView = glass
            container.hostingView = hosting
            container.scheduleBackdropSetup()
        } else {
            // Fallback: NSVisualEffectView with content as subview
            let blur = NSVisualEffectView(frame: .zero)
            blur.translatesAutoresizingMaskIntoConstraints = false
            blur.material     = .hudWindow
            blur.blendingMode = .behindWindow
            blur.state        = .active

            let hosting = NSHostingView(rootView: AnyView(content))
            hosting.translatesAutoresizingMaskIntoConstraints = false
            blur.addSubview(hosting)
            container.addSubview(blur)
            NSLayoutConstraint.activate([
                blur.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                blur.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                blur.topAnchor.constraint(equalTo: container.topAnchor),
                blur.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                hosting.leadingAnchor.constraint(equalTo: blur.leadingAnchor),
                hosting.trailingAnchor.constraint(equalTo: blur.trailingAnchor),
                hosting.topAnchor.constraint(equalTo: blur.topAnchor),
                hosting.bottomAnchor.constraint(equalTo: blur.bottomAnchor),
            ])
            container.hostingView = hosting
        }

        return container
    }

    func updateNSView(_ nsView: GlassContainerView, context: Context) {
        nsView.hostingView?.rootView = AnyView(content)
        if let glass = nsView.glassView {
            glass.setValue(cornerRadius, forKey: "cornerRadius")
            applyGlassVariant(glass, variant: variant)
        }
        nsView.scheduleBackdropSetup()
    }
}


// MARK: - Root View

struct WeatherView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @EnvironmentObject var settings: SettingsStore
    @State private var showSettings = false

    var body: some View {
        Group {
            if settings.glassStyle == .clear {
                // Atoll approach: content embedded inside NSGlassEffectView via contentView KVC.
                // This lets the glass own the content boundary and produce correct edge refraction.
                LiquidGlassBackground(variant: 11, cornerRadius: 28) {
                    contentGroup
                        .environmentObject(settings)
                }
                .overlay(
                    // Soften the concentrated white/black specular at the corners:
                    // a blurred neutral-gray ring partially fills both extremes.
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color(white: 0.5, opacity: 0.18), lineWidth: 2)
                        .blur(radius: 2)
                )
            } else {
                ZStack {
                    FrostedGlassBackground()
                    contentGroup
                    // Frosted border
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
        .frame(width: 280, height: 380)
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

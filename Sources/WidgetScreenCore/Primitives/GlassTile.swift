import AppKit
import SwiftUI

// MARK: - Private Glass Variant Helper

typealias VariantSetterIMP = @convention(c) (AnyObject, Selector, Int) -> Void

/// Sets NSGlassEffectView's private variant via runtime IMP dispatch.
/// Variant 11 is the Liquid Glass look Apple uses for lock-screen panels.
public func applyGlassVariant(_ glass: NSView, variant: Int) {
    let sel = NSSelectorFromString("set_variant:")
    guard let m = class_getInstanceMethod(object_getClass(glass), sel) else { return }
    unsafeBitCast(method_getImplementation(m), to: VariantSetterIMP.self)(glass, sel, variant)
}

// MARK: - GlassContainerView

/// Keeps `CABackdropLayer.windowServerAware = true` and `scale = 1.0` while the window
/// lives in a SkyLight compositor space. Without this the blur goes dead after the
/// space transition because the compositor resets those properties.
public final class GlassContainerView: NSView {
    public weak var glassView: NSView?
    public var hostingView: NSHostingView<AnyView>?

    private var observedBackdropLayers: [CALayer] = []
    private var setupScheduled = false

    deinit { removeBackdropObservers() }

    public override func removeFromSuperview() {
        removeBackdropObservers()
        super.removeFromSuperview()
    }

    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        scheduleBackdropSetup()
    }

    public override func layout() {
        super.layout()
        scheduleBackdropSetup()
    }

    public func scheduleBackdropSetup() {
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

    public override func observeValue(
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

// MARK: - FrostedGlassBackground (SwiftUI Representable)

/// NSGlassEffectView as a background layer only (no content embedding).
public struct FrostedGlassBackground: NSViewRepresentable {
    public init() {}

    public func makeNSView(context: Context) -> GlassContainerView {
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

    public func updateNSView(_ nsView: GlassContainerView, context: Context) {}
}

// MARK: - LiquidGlassBackground (SwiftUI Representable)

/// Embeds SwiftUI content as `NSGlassEffectView.contentView` so the glass effect
/// owns the content boundary and produces correct edge refraction.
public struct LiquidGlassBackground<Content: View>: NSViewRepresentable {
    public var variant: Int
    public var cornerRadius: CGFloat
    public var content: Content

    public init(variant: Int = 11, cornerRadius: CGFloat = 28, @ViewBuilder content: () -> Content) {
        self.variant = variant
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public func makeNSView(context: Context) -> GlassContainerView {
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

    public func updateNSView(_ nsView: GlassContainerView, context: Context) {
        nsView.hostingView?.rootView = AnyView(content)
        if let glass = nsView.glassView {
            glass.setValue(cornerRadius, forKey: "cornerRadius")
            applyGlassVariant(glass, variant: variant)
        }
        nsView.scheduleBackdropSetup()
    }
}

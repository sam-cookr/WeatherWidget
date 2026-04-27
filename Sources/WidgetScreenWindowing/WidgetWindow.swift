import AppKit
import SwiftUI
import WidgetScreenCore

/// One NSWindow hosting a single widget instance on the lock-screen compositor space.
/// The SwiftUI content (passed as AnyView) owns its own glass background via
/// FrostedGlassBackground / LiquidGlassBackground from WidgetScreenCore.
@MainActor
public final class WidgetWindow {
    public private(set) var instance: WidgetInstance
    public let nsWindow: NSWindow
    private let hostingController: NSHostingController<AnyView>

    public init(instance: WidgetInstance, content: AnyView, size: CGSize) {
        self.instance = instance

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask:   [.borderless, .fullSizeContentView],
            backing:     .buffered,
            defer:       false
        )
        window.isOpaque                     = false
        window.backgroundColor              = .clear
        window.hasShadow                    = false
        window.titleVisibility              = .hidden
        window.titlebarAppearsTransparent   = true
        window.isMovable                    = false
        window.canBecomeVisibleWithoutLogin = true
        window.level                        = .init(rawValue: .init(Int32.max - 2))
        window.collectionBehavior           = [.fullScreenAuxiliary, .stationary, .canJoinAllSpaces, .ignoresCycle]
        window.isReleasedWhenClosed         = false
        window.contentView?.wantsLayer      = true
        window.contentView?.layer?.cornerRadius = 28
        window.contentView?.layer?.cornerCurve  = .continuous
        window.contentView?.layer?.masksToBounds = true

        let hosting = NSHostingController(rootView: content)
        window.contentViewController = hosting

        self.nsWindow = window
        self.hostingController = hosting

        SkyLightCoordinator.shared.addWindow(window)
    }

    public func update(content: AnyView) {
        hostingController.rootView = content
    }

    public func setFrame(origin: NSPoint, size: CGSize) {
        nsWindow.setContentSize(size)
        nsWindow.setFrameOrigin(origin)
        nsWindow.contentView?.layer?.cornerRadius = 28
    }

    public func show() { nsWindow.makeKeyAndOrderFront(nil) }
    public func hide() { nsWindow.orderOut(nil) }
}

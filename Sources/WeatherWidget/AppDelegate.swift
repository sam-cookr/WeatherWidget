import AppKit
import SwiftUI
import SkyLightWindow
import Combine
import Darwin

class AppDelegate: NSObject, NSApplicationDelegate {
    var floatingWindow: NSWindow?
    var viewModel: WeatherViewModel?
    let settings = SettingsStore()
    private let glassProbeOnly: Bool
    private let glassExperimental: Bool
    private var cancellables = Set<AnyCancellable>()

    init(glassProbeOnly: Bool = false, glassExperimental: Bool = false) {
        self.glassProbeOnly = glassProbeOnly
        self.glassExperimental = glassExperimental
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.prohibited)
        if glassProbeOnly {
            setupGlassProbeWindow()
            return
        }
        setupFloatingWindow()
        registerScreenNotifications()
        observeSettings()
    }

    @MainActor private func setupGlassProbeWindow() {
        let probe = LockScreenGlassProbeView()
        let hosting = NSHostingController(rootView: probe)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 180),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hosting
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovable = false
        window.canBecomeVisibleWithoutLogin = true
        window.level = .init(rawValue: .init(Int32.max - 2))
        window.collectionBehavior = [.fullScreenAuxiliary, .stationary, .canJoinAllSpaces, .ignoresCycle]
        window.isReleasedWhenClosed = false
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = 28
        window.contentView?.layer?.cornerCurve = .continuous
        window.contentView?.layer?.masksToBounds = true

        if glassExperimental {
            delegateWindowToExperimentalSkySpace(window)
        } else {
            SkyLightOperator.shared.delegateWindow(window)
        }
        floatingWindow = window

        if let screen = NSScreen.main {
            let vf = screen.visibleFrame
            window.setFrameOrigin(NSPoint(x: vf.maxX - 280 - 20, y: vf.maxY - 180 - 20))
        }
        window.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        DistributedNotificationCenter.default().removeObserver(self)
    }

    // MARK: - Settings Observers

    private func observeSettings() {
        settings.$position
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pos in self?.repositionWindow(to: pos) }
            .store(in: &cancellables)
    }

    // MARK: - Screen Lock / Screensaver

    private func registerScreenNotifications() {
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(self, selector: #selector(screenObscured),
                        name: NSNotification.Name("com.apple.screensaver.didstart"), object: nil)
        dnc.addObserver(self, selector: #selector(screenObscured),
                        name: NSNotification.Name("com.apple.screenIsLocked"),       object: nil)
        dnc.addObserver(self, selector: #selector(screenRevealed),
                        name: NSNotification.Name("com.apple.screensaver.didstop"),  object: nil)
        dnc.addObserver(self, selector: #selector(screenRevealed),
                        name: NSNotification.Name("com.apple.screenIsUnlocked"),     object: nil)
    }

    @objc private func screenObscured() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self, let window = self.floatingWindow else { return }
            window.makeKeyAndOrderFront(nil)
            // Re-apply position in case SkyLight shifted it
            if let screen = NSScreen.main {
                window.setFrameOrigin(
                    self.origin(for: self.settings.position,
                                windowSize: window.frame.size,
                                screen: screen)
                )
            }
        }
    }

    @objc private func screenRevealed() {
        floatingWindow?.orderOut(nil)
    }

    // MARK: - Floating Window

    @MainActor private func setupFloatingWindow() {
        let vm = WeatherViewModel(settings: settings)
        self.viewModel = vm

        let contentView = WeatherView(viewModel: vm)
            .environmentObject(settings)
        let hosting = NSHostingController(rootView: contentView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 380),
            styleMask:   [.borderless, .fullSizeContentView],
            backing:     .buffered,
            defer:       false
        )
        window.contentViewController        = hosting
        window.isOpaque                     = false
        window.backgroundColor              = .clear
        window.hasShadow                    = false
        window.titleVisibility              = .hidden
        window.titlebarAppearsTransparent   = true
        window.isMovable                    = false
        window.canBecomeVisibleWithoutLogin = true
        window.level = .init(rawValue: .init(Int32.max - 2))
        window.collectionBehavior = [
            .fullScreenAuxiliary,
            .stationary,
            .canJoinAllSpaces,
            .ignoresCycle,
        ]
        window.isReleasedWhenClosed = false
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = 28
        window.contentView?.layer?.cornerCurve = .continuous
        window.contentView?.layer?.masksToBounds = true

        if glassExperimental {
            delegateWindowToExperimentalSkySpace(window)
        } else {
            SkyLightOperator.shared.delegateWindow(window)
        }
        floatingWindow = window

        // Delay placement so SkyLight's internal setup doesn't override us
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self, let w = self.floatingWindow, let screen = NSScreen.main else { return }
            w.setFrameOrigin(self.origin(for: self.settings.position,
                                         windowSize: w.frame.size,
                                         screen: screen))
        }

        Task { await vm.fetch() }
    }

    // MARK: - Positioning

    private func repositionWindow(to position: WidgetPosition) {
        guard let window = floatingWindow, let screen = NSScreen.main else { return }
        let target = origin(for: position, windowSize: window.frame.size, screen: screen)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration       = 0.45
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrameOrigin(target)
        }
    }

    /// Returns the bottom-left origin for `position` using `screen.visibleFrame`
    /// (excludes menu bar and Dock so the widget is always fully on-screen).
    private func origin(for position: WidgetPosition, windowSize: CGSize, screen: NSScreen) -> NSPoint {
        let vf     = screen.visibleFrame   // excludes menu bar + Dock
        let margin: CGFloat = 20
        let w      = windowSize.width
        let h      = windowSize.height

        switch position {
        case .topRight:
            return NSPoint(x: vf.maxX - w - margin, y: vf.maxY - h - margin)
        case .topLeft:
            return NSPoint(x: vf.minX + margin,     y: vf.maxY - h - margin)
        case .bottomRight:
            return NSPoint(x: vf.maxX - w - margin, y: vf.minY + margin)
        case .bottomLeft:
            return NSPoint(x: vf.minX + margin,     y: vf.minY + margin)
        }
    }

    /// Experimental SkyLight space placement: use screen-lock absolute level (300)
    /// instead of NotificationCenter-at-lock level (400).
    private func delegateWindowToExperimentalSkySpace(_ window: NSWindow) {
        typealias F_SLSMainConnectionID = @convention(c) () -> Int32
        typealias F_SLSSpaceCreate = @convention(c) (Int32, Int32, Int32) -> Int32
        typealias F_SLSSpaceSetAbsoluteLevel = @convention(c) (Int32, Int32, Int32) -> Int32
        typealias F_SLSShowSpaces = @convention(c) (Int32, CFArray) -> Int32
        typealias F_SLSSpaceAddWindowsAndRemoveFromSpaces = @convention(c) (Int32, Int32, CFArray, Int32) -> Int32

        guard let handler = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight", RTLD_NOW),
              let symConn = dlsym(handler, "SLSMainConnectionID"),
              let symCreate = dlsym(handler, "SLSSpaceCreate"),
              let symSetLevel = dlsym(handler, "SLSSpaceSetAbsoluteLevel"),
              let symShow = dlsym(handler, "SLSShowSpaces"),
              let symAdd = dlsym(handler, "SLSSpaceAddWindowsAndRemoveFromSpaces") else {
            SkyLightOperator.shared.delegateWindow(window)
            return
        }

        let SLSMainConnectionID = unsafeBitCast(symConn, to: F_SLSMainConnectionID.self)
        let SLSSpaceCreate = unsafeBitCast(symCreate, to: F_SLSSpaceCreate.self)
        let SLSSpaceSetAbsoluteLevel = unsafeBitCast(symSetLevel, to: F_SLSSpaceSetAbsoluteLevel.self)
        let SLSShowSpaces = unsafeBitCast(symShow, to: F_SLSShowSpaces.self)
        let SLSSpaceAddWindowsAndRemoveFromSpaces = unsafeBitCast(symAdd, to: F_SLSSpaceAddWindowsAndRemoveFromSpaces.self)

        let connection = SLSMainConnectionID()
        let space = SLSSpaceCreate(connection, 1, 0)
        _ = SLSSpaceSetAbsoluteLevel(connection, space, 300)
        _ = SLSShowSpaces(connection, [space] as CFArray)
        _ = SLSSpaceAddWindowsAndRemoveFromSpaces(connection, space, [window.windowNumber] as CFArray, 7)
    }
}

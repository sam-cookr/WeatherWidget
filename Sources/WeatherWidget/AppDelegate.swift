import AppKit
import SwiftUI
import SkyLightWindow
import Combine
import Darwin

class AppDelegate: NSObject, NSApplicationDelegate {
    var floatingWindow: NSWindow?
    var viewModel: WeatherViewModel?
    let settings = SettingsStore()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.prohibited)
        setupFloatingWindow()
        registerScreenNotifications()
        observeSettings()
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
            guard let self, let window = self.floatingWindow, let screen = NSScreen.main else { return }
            window.makeKeyAndOrderFront(nil)
            window.setFrameOrigin(self.origin(for: self.settings.position,
                                              windowSize: window.frame.size,
                                              screen: screen))
        }
    }

    @objc private func screenRevealed() {
        floatingWindow?.orderOut(nil)
    }

    // MARK: - Floating Window

    @MainActor private func setupFloatingWindow() {
        let vm = WeatherViewModel(settings: settings)
        self.viewModel = vm

        let hosting = NSHostingController(
            rootView: WeatherView(viewModel: vm).environmentObject(settings)
        )

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
        window.collectionBehavior = [.fullScreenAuxiliary, .stationary, .canJoinAllSpaces, .ignoresCycle]
        window.isReleasedWhenClosed = false
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = 28
        window.contentView?.layer?.cornerCurve = .continuous
        window.contentView?.layer?.masksToBounds = true

        delegateWindowToSkySpace(window)
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
        window.setFrameOrigin(origin(for: position, windowSize: window.frame.size, screen: screen))
    }

    private func origin(for position: WidgetPosition, windowSize: CGSize, screen: NSScreen) -> NSPoint {
        let f      = screen.frame   // use full frame so lock-screen and desktop positions match
        let margin: CGFloat = 20
        let w      = windowSize.width
        let h      = windowSize.height

        switch position {
        case .topRight:    return NSPoint(x: f.maxX - w - margin, y: f.maxY - h - margin)
        case .topLeft:     return NSPoint(x: f.minX + margin,     y: f.maxY - h - margin)
        case .bottomRight: return NSPoint(x: f.maxX - w - margin, y: f.minY + margin)
        case .bottomLeft:  return NSPoint(x: f.minX + margin,     y: f.minY + margin)
        }
    }

    // MARK: - SkyLight Space Placement
    //
    // Places the window in a SkyLight compositor space at level 300, which makes it
    // visible on the macOS lock screen without Screen Recording permission.

    private func delegateWindowToSkySpace(_ window: NSWindow) {
        typealias ConnectionID = @convention(c) () -> Int32
        typealias SpaceCreate  = @convention(c) (Int32, Int32, Int32) -> Int32
        typealias SpaceLevel   = @convention(c) (Int32, Int32, Int32) -> Int32
        typealias ShowSpaces   = @convention(c) (Int32, CFArray) -> Int32
        typealias AddWindows   = @convention(c) (Int32, Int32, CFArray, Int32) -> Int32

        guard
            let lib      = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight", RTLD_NOW),
            let symConn   = dlsym(lib, "SLSMainConnectionID"),
            let symCreate = dlsym(lib, "SLSSpaceCreate"),
            let symLevel  = dlsym(lib, "SLSSpaceSetAbsoluteLevel"),
            let symShow   = dlsym(lib, "SLSShowSpaces"),
            let symAdd    = dlsym(lib, "SLSSpaceAddWindowsAndRemoveFromSpaces")
        else {
            // Fallback to the SkyLightWindow package if private APIs are unavailable
            SkyLightOperator.shared.delegateWindow(window)
            return
        }

        let conn   = unsafeBitCast(symConn,   to: ConnectionID.self)()
        let create = unsafeBitCast(symCreate,  to: SpaceCreate.self)
        let level  = unsafeBitCast(symLevel,   to: SpaceLevel.self)
        let show   = unsafeBitCast(symShow,    to: ShowSpaces.self)
        let add    = unsafeBitCast(symAdd,     to: AddWindows.self)

        let space = create(conn, 1, 0)
        _ = level(conn, space, 300)
        _ = show(conn, [space] as CFArray)
        _ = add(conn, space, [window.windowNumber] as CFArray, 7)
    }
}

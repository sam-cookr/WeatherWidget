import AppKit
import SwiftUI
import SkyLightWindow
import Combine
import Darwin

class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    var floatingWindow: NSWindow?
    var viewModel: WeatherViewModel?
    let settings = SettingsStore()

    private var statusItem: NSStatusItem?
    private var preferencesWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        // .accessory = no Dock icon, no Cmd-Tab entry; status item is the only UI entry point
        NSApp.setActivationPolicy(.accessory)
        setupMenuBar()
        setupFloatingWindow()
        registerScreenNotifications()
        observeSettings()

        if !UserDefaults.standard.bool(forKey: "ww.onboardingComplete") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.openOnboarding() }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        DistributedNotificationCenter.default().removeObserver(self)
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }

        let cfg = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        button.image = NSImage(
            systemSymbolName: "cloud.sun.fill",
            accessibilityDescription: "WeatherWidget"
        )?.withSymbolConfiguration(cfg)
        button.image?.isTemplate = true

        let menu = NSMenu()

        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit WeatherWidget",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    // MARK: - Preferences Window

    @objc func openPreferences() {
        if preferencesWindow == nil {
            let view = PreferencesView()
                .environmentObject(settings)
            let vc = NSHostingController(rootView: view)
            let win = NSWindow(contentViewController: vc)
            win.title = "WeatherWidget"
            win.styleMask = [.titled, .closable, .miniaturizable]
            win.setContentSize(NSSize(width: 720, height: 480))
            win.center()
            win.isReleasedWhenClosed = false
            win.minSize = NSSize(width: 620, height: 400)

            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: win,
                queue: .main
            ) { [weak self] _ in self?.preferencesWindow = nil }

            preferencesWindow = win
        }
        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Onboarding Window

    func openOnboarding() {
        if onboardingWindow == nil {
            let view = OnboardingView {
                self.onboardingWindow?.close()
            }
            .environmentObject(settings)
            let vc = NSHostingController(rootView: view)
            let win = NSWindow(contentViewController: vc)
            win.styleMask = [.titled, .closable, .fullSizeContentView]
            win.titleVisibility = .hidden
            win.titlebarAppearsTransparent = true
            win.isMovableByWindowBackground = true
            win.setContentSize(NSSize(width: 540, height: 500))
            win.center()
            win.isReleasedWhenClosed = false

            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: win,
                queue: .main
            ) { [weak self] _ in self?.onboardingWindow = nil }

            onboardingWindow = win
        }
        onboardingWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
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

    // MARK: - Floating Widget Window

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
        let f = screen.frame
        let margin: CGFloat = 20
        let w = windowSize.width
        let h = windowSize.height
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
            let lib       = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight", RTLD_NOW),
            let symConn   = dlsym(lib, "SLSMainConnectionID"),
            let symCreate = dlsym(lib, "SLSSpaceCreate"),
            let symLevel  = dlsym(lib, "SLSSpaceSetAbsoluteLevel"),
            let symShow   = dlsym(lib, "SLSShowSpaces"),
            let symAdd    = dlsym(lib, "SLSSpaceAddWindowsAndRemoveFromSpaces")
        else {
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

import AppKit
import SwiftUI
import SkyLightWindow
import Combine

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

        SkyLightOperator.shared.delegateWindow(window)
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
}

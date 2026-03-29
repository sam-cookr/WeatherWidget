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

        settings.$glassIntensity
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, let w = self.floatingWindow else { return }
                Task { @MainActor in self.viewModel?.generateGlassBackground(windowFrame: w.frame) }
            }
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
            self?.floatingWindow?.makeKeyAndOrderFront(nil)
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
        window.contentViewController      = hosting
        window.isOpaque                   = false
        window.backgroundColor            = .clear
        window.hasShadow                  = false
        window.titleVisibility            = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovable                  = false
        window.canBecomeVisibleWithoutLogin = true
        window.level = .init(rawValue: .init(Int32.max - 2))
        window.collectionBehavior = [
            .fullScreenAuxiliary,
            .stationary,
            .canJoinAllSpaces,
            .ignoresCycle,
        ]
        window.isReleasedWhenClosed = false

        placeWindow(window, at: settings.position)

        SkyLightOperator.shared.delegateWindow(window)
        floatingWindow = window

        Task { await vm.fetch() }
        vm.generateGlassBackground(windowFrame: window.frame)
    }

    // MARK: - Positioning

    private func placeWindow(_ window: NSWindow, at position: WidgetPosition) {
        guard let screen = NSScreen.main else { return }
        window.setFrameOrigin(origin(for: position, windowSize: window.frame.size, screen: screen))
    }

    private func repositionWindow(to position: WidgetPosition) {
        guard let window = floatingWindow, let screen = NSScreen.main else { return }
        let target = origin(for: position, windowSize: window.frame.size, screen: screen)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration        = 0.45
            ctx.timingFunction  = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrameOrigin(target)
        } completionHandler: { [weak self] in
            guard let self, let w = self.floatingWindow else { return }
            Task { @MainActor in self.viewModel?.generateGlassBackground(windowFrame: w.frame) }
        }
    }

    private func origin(for position: WidgetPosition, windowSize: CGSize, screen: NSScreen) -> NSPoint {
        let sf     = screen.frame
        let margin: CGFloat = 32
        let w      = windowSize.width
        let h      = windowSize.height

        switch position {
        case .topRight:
            return NSPoint(x: sf.maxX - w - margin,  y: sf.maxY - h - margin - 80)
        case .topLeft:
            return NSPoint(x: sf.minX + margin,       y: sf.maxY - h - margin - 80)
        case .bottomRight:
            return NSPoint(x: sf.maxX - w - margin,   y: sf.minY + margin + 80)
        case .bottomLeft:
            return NSPoint(x: sf.minX + margin,        y: sf.minY + margin + 80)
        }
    }
}

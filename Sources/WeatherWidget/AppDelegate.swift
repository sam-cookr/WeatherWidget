import AppKit
import SwiftUI
import Combine
import WidgetScreenCore
import WidgetScreenWindowing

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    var viewModel: WeatherViewModel?
    let settings = SettingsStore()

    private var statusItem: NSStatusItem?
    private var preferencesWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    private var isWidgetVisible = false
    private var toggleMenuItem: NSMenuItem?
    private var weatherInstanceID: UUID?

    // MARK: - Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupApplicationMenu()
        setupMenuBar()
        setupWidget()
        observeSettings()
        applyInterfaceMode()

        SkyLightCoordinator.shared.registerNotifications(
            onObscured: { [weak self] in self?.screenObscured() },
            onRevealed: { [weak self] in self?.screenRevealed() },
            onWake:     { [weak self] in
                guard let vm = self?.viewModel else { return }
                Task { await vm.fetch(force: true) }
            }
        )

        if !UserDefaults.standard.bool(forKey: "ww.onboardingComplete") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.openOnboarding() }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        DistributedNotificationCenter.default().removeObserver(self)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows { openPreferences() }
        return true
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        guard statusItem == nil else { return }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }

        let cfg = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        button.image = NSImage(
            systemSymbolName: "cloud.sun.fill",
            accessibilityDescription: "WeatherWidget"
        )?.withSymbolConfiguration(cfg)
        button.image?.isTemplate = true

        let menu = NSMenu()

        let toggle = NSMenuItem(title: "Show Widget", action: #selector(toggleWidget), keyEquivalent: "w")
        toggle.target = self
        menu.addItem(toggle)
        toggleMenuItem = toggle

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openPreferences), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(
            title: "Quit WeatherWidget",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        statusItem?.menu = menu
    }

    private func tearDownMenuBar() {
        guard let statusItem else { return }
        NSStatusBar.system.removeStatusItem(statusItem)
        self.statusItem = nil
        toggleMenuItem = nil
    }

    private func setupApplicationMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openPreferences), keyEquivalent: ",")
        settingsItem.target = self
        appMenu.addItem(settingsItem)
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(
            title: "Quit WeatherWidget",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        appMenuItem.submenu = appMenu
        NSApp.mainMenu = mainMenu
    }

    private func applyInterfaceMode() {
        NSApp.setActivationPolicy(.accessory)
        settings.showMenuBarIcon ? setupMenuBar() : tearDownMenuBar()
    }

    // MARK: - Widget Toggle

    @objc func toggleWidget() {
        guard let id = weatherInstanceID, let win = WindowManager.shared.window(for: id) else { return }
        if isWidgetVisible {
            win.hide()
            isWidgetVisible = false
            toggleMenuItem?.title = "Show Widget"
        } else {
            repositionWidgets()
            win.show()
            isWidgetVisible = true
            toggleMenuItem?.title = "Hide Widget"
        }
    }

    // MARK: - Preferences Window

    @objc func openPreferences() {
        if preferencesWindow == nil {
            let view = PreferencesView().environmentObject(settings)
            let vc = NSHostingController(rootView: view)
            let win = NSWindow(contentViewController: vc)
            win.title = "WeatherWidget"
            win.styleMask = [.titled, .closable, .miniaturizable]
            win.setContentSize(NSSize(width: 960, height: 540))
            win.center()
            win.isReleasedWhenClosed = false
            win.minSize = NSSize(width: 820, height: 480)
            win.appearance = NSAppearance(named: .darkAqua)
            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification, object: win, queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.preferencesWindow = nil
                    self?.applyInterfaceMode()
                }
            }
            preferencesWindow = win
        }
        presentUserWindow(preferencesWindow)
    }

    // MARK: - Onboarding Window

    func openOnboarding() {
        if onboardingWindow == nil {
            let view = OnboardingView { self.onboardingWindow?.close() }
                .environmentObject(settings)
            let vc = NSHostingController(rootView: view)
            let win = NSWindow(contentViewController: vc)
            win.styleMask = [.titled, .closable, .fullSizeContentView]
            win.titleVisibility = .hidden
            win.titlebarAppearsTransparent = true
            win.isMovableByWindowBackground = true
            win.setContentSize(NSSize(width: 540, height: 540))
            win.center()
            win.isReleasedWhenClosed = false
            win.appearance = NSAppearance(named: .darkAqua)
            win.level = .floating
            win.collectionBehavior = [.moveToActiveSpace]
            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification, object: win, queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    if !UserDefaults.standard.bool(forKey: "ww.onboardingComplete") {
                        UserDefaults.standard.set(true, forKey: "ww.onboardingComplete")
                    }
                    self?.onboardingWindow = nil
                    self?.applyInterfaceMode()
                }
            }
            onboardingWindow = win
        }
        presentUserWindow(onboardingWindow)
    }

    private func presentUserWindow(_ window: NSWindow?) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Settings Observers

    private func observeSettings() {
        settings.$position
            .dropFirst().receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.repositionWidgets() }
            .store(in: &cancellables)

        settings.$widgetSize
            .dropFirst().receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.repositionWidgets() }
            .store(in: &cancellables)

        settings.$targetScreenName
            .dropFirst().receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.repositionWidgets() }
            .store(in: &cancellables)

        settings.$showMenuBarIcon
            .dropFirst().receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.applyInterfaceMode() }
            .store(in: &cancellables)
    }

    // MARK: - Screen Lock / Wake

    private func screenObscured() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.repositionWidgets()
            WindowManager.shared.showAll()
        }
    }

    private func screenRevealed() {
        guard settings.autoHideOnUnlock else { return }
        WindowManager.shared.hideAll()
        isWidgetVisible = false
        toggleMenuItem?.title = "Show Widget"
    }

    // MARK: - Widget Window Setup

    @MainActor private func setupWidget() {
        let vm = WeatherViewModel(settings: settings)
        self.viewModel = vm

        // Seed LayoutStore with a single weather instance if empty.
        if LayoutStore.shared.instances.isEmpty {
            let instance = WidgetInstance(typeID: "weather", size: .medium, gridOrigin: .zero)
            weatherInstanceID = instance.id
            LayoutStore.shared.add(instance)
        } else {
            weatherInstanceID = LayoutStore.shared.instances.first?.id
        }

        WindowManager.shared.configure(
            viewFactory: { [weak self] _ in
                guard let self else { return AnyView(EmptyView()) }
                return AnyView(WeatherView(viewModel: vm).environmentObject(self.settings))
            },
            sizeProvider: { [weak self] _ in
                self?.settings.widgetSize.windowSize ?? CGSize(width: 320, height: 180)
            }
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.repositionWidgets()
            WindowManager.shared.showAll()
            self?.isWidgetVisible = true
            self?.toggleMenuItem?.title = "Hide Widget"
        }

        Task { await vm.fetch() }
    }

    // MARK: - Positioning

    private var selectedScreen: NSScreen? {
        let name = settings.targetScreenName
        if name.isEmpty { return NSScreen.main }
        return NSScreen.screens.first { $0.localizedName == name } ?? NSScreen.main
    }

    private func repositionWidgets() {
        guard let screen = selectedScreen else { return }
        WindowManager.shared.repositionAll(
            origin: { [weak self] _ in
                guard let self else { return .zero }
                return self.origin(for: self.settings.position,
                                   windowSize: self.settings.widgetSize.windowSize,
                                   screen: screen)
            },
            size: { [weak self] _ in
                self?.settings.widgetSize.windowSize ?? CGSize(width: 320, height: 180)
            }
        )
    }

    private func origin(for position: WidgetPosition, windowSize: CGSize, screen: NSScreen) -> NSPoint {
        let f = screen.frame
        let margin: CGFloat = 20
        switch position {
        case .topRight:    return NSPoint(x: f.maxX - windowSize.width  - margin, y: f.maxY - windowSize.height - margin)
        case .topLeft:     return NSPoint(x: f.minX + margin,                     y: f.maxY - windowSize.height - margin)
        case .bottomRight: return NSPoint(x: f.maxX - windowSize.width  - margin, y: f.minY + margin)
        case .bottomLeft:  return NSPoint(x: f.minX + margin,                     y: f.minY + margin)
        }
    }
}

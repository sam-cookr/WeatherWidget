import AppKit
import SwiftUI
import Combine
import WidgetScreenCore

/// Owns the live set of WidgetWindows, one per WidgetInstance in LayoutStore.
/// Callers supply a view factory so this target stays decoupled from widget implementations.
@MainActor
public final class WindowManager: ObservableObject {
    public static let shared = WindowManager()

    private var windows: [UUID: WidgetWindow] = [:]
    private var viewFactory: ((WidgetInstance) -> AnyView)?
    private var sizeProvider: ((WidgetInstance) -> CGSize)?
    private var layoutCancellable: AnyCancellable?

    private init() {}

    // MARK: - Configuration

    /// Call once at launch. `viewFactory` returns the SwiftUI content for a given instance.
    /// `sizeProvider` returns the window size (may change as settings change).
    public func configure(
        viewFactory:  @escaping (WidgetInstance) -> AnyView,
        sizeProvider: @escaping (WidgetInstance) -> CGSize
    ) {
        self.viewFactory  = viewFactory
        self.sizeProvider = sizeProvider
        SkyLightCoordinator.shared.setupSharedSpace()
        observeLayout()
    }

    // MARK: - Layout diffing

    private func observeLayout() {
        layoutCancellable = LayoutStore.shared.$instances
            .receive(on: DispatchQueue.main)
            .sink { [weak self] instances in self?.sync(to: instances) }
    }

    private func sync(to instances: [WidgetInstance]) {
        guard let factory = viewFactory, let sizeFn = sizeProvider else { return }
        let (toAdd, toRemove) = WindowManager.diff(newInstances: instances, existingIDs: Set(windows.keys))
        for id in toRemove {
            windows[id]?.hide()
            windows[id] = nil
        }
        for instance in toAdd {
            let win = WidgetWindow(instance: instance, content: factory(instance), size: sizeFn(instance))
            windows[instance.id] = win
        }
    }

    // Pure function — testable without NSWindow.
    public nonisolated static func diff(
        newInstances: [WidgetInstance],
        existingIDs: Set<UUID>
    ) -> (toAdd: [WidgetInstance], toRemove: Set<UUID>) {
        let newIDs = Set(newInstances.map(\.id))
        return (
            toAdd:    newInstances.filter { !existingIDs.contains($0.id) },
            toRemove: existingIDs.subtracting(newIDs)
        )
    }

    // MARK: - Visibility

    public func showAll() { windows.values.forEach { $0.show() } }
    public func hideAll() { windows.values.forEach { $0.hide() } }

    // MARK: - Positioning

    /// Repositions and resizes all windows using caller-supplied closures.
    public func repositionAll(
        origin: (WidgetInstance) -> NSPoint,
        size:   (WidgetInstance) -> CGSize
    ) {
        for (id, win) in windows {
            guard let instance = LayoutStore.shared.instances.first(where: { $0.id == id }) else { continue }
            win.setFrame(origin: origin(instance), size: size(instance))
        }
    }

    public func window(for id: UUID) -> WidgetWindow? { windows[id] }
}

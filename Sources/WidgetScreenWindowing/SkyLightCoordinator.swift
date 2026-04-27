import AppKit
import Darwin
import SkyLightWindow
import WidgetScreenCore

/// Manages one shared SkyLight compositor space at level 300 and routes
/// lock/unlock/wake notifications to caller-supplied callbacks.
///
/// One shared space is the right model: `SLSSpaceAddWindowsAndRemoveFromSpaces`
/// accepts a CFArray so batching is native, and a single space means one
/// level-300 placement + atomic show/hide for all widgets.
@MainActor
public final class SkyLightCoordinator {
    public static let shared = SkyLightCoordinator()

    private typealias ConnectionFn = @convention(c) () -> Int32
    private typealias SpaceCreateFn = @convention(c) (Int32, Int32, Int32) -> Int32
    private typealias SpaceLevelFn = @convention(c) (Int32, Int32, Int32) -> Int32
    private typealias ShowSpacesFn = @convention(c) (Int32, CFArray) -> Int32
    private typealias AddWindowsFn = @convention(c) (Int32, Int32, CFArray, Int32) -> Int32

    private var connectionID: Int32 = 0
    private var spaceID: Int32 = 0
    private var addWindowsFn: AddWindowsFn?
    private var spaceReady = false

    private init() {}

    // MARK: - Space setup

    public func setupSharedSpace() {
        guard !spaceReady else { return }
        guard
            let lib       = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight", RTLD_NOW),
            let symConn   = dlsym(lib, "SLSMainConnectionID"),
            let symCreate = dlsym(lib, "SLSSpaceCreate"),
            let symLevel  = dlsym(lib, "SLSSpaceSetAbsoluteLevel"),
            let symShow   = dlsym(lib, "SLSShowSpaces"),
            let symAdd    = dlsym(lib, "SLSSpaceAddWindowsAndRemoveFromSpaces")
        else { return }

        let conn   = unsafeBitCast(symConn,   to: ConnectionFn.self)()
        let create = unsafeBitCast(symCreate,  to: SpaceCreateFn.self)
        let level  = unsafeBitCast(symLevel,   to: SpaceLevelFn.self)
        let show   = unsafeBitCast(symShow,    to: ShowSpacesFn.self)
        let add    = unsafeBitCast(symAdd,     to: AddWindowsFn.self)

        let space = create(conn, 1, 0)
        _ = level(conn, space, 300)
        _ = show(conn, [space] as CFArray)

        connectionID = conn
        spaceID = space
        addWindowsFn = add
        spaceReady = true
    }

    /// Adds a window to the shared SkyLight space. Falls back to `SkyLightOperator`
    /// if the private API is unavailable.
    public func addWindow(_ window: NSWindow) {
        if let add = addWindowsFn {
            _ = add(connectionID, spaceID, [window.windowNumber] as CFArray, 7)
        } else {
            SkyLightOperator.shared.delegateWindow(window)
        }
    }

    // MARK: - Notifications

    public func registerNotifications(
        onObscured: @escaping @MainActor () -> Void,
        onRevealed: @escaping @MainActor () -> Void,
        onWake:     @escaping @MainActor () -> Void
    ) {
        let dnc = DistributedNotificationCenter.default()
        for name in ["com.apple.screensaver.didstart", "com.apple.screenIsLocked"] {
            dnc.addObserver(
                forName: Notification.Name(name), object: nil, queue: .main
            ) { _ in Task { @MainActor in onObscured() } }
        }
        for name in ["com.apple.screensaver.didstop", "com.apple.screenIsUnlocked"] {
            dnc.addObserver(
                forName: Notification.Name(name), object: nil, queue: .main
            ) { _ in Task { @MainActor in onRevealed() } }
        }
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { _ in Task { @MainActor in onWake() } }
    }
}

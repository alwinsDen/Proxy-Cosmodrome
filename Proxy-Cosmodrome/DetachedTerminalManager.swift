import SwiftUI
import AppKit

private class DetachedWindowDelegate: NSObject, NSWindowDelegate {
    let instanceId: UUID
    unowned let runnerManager: RunnerManager

    init(instanceId: UUID, runnerManager: RunnerManager) {
        self.instanceId = instanceId
        self.runnerManager = runnerManager
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        runnerManager.stopRunner(id: instanceId)
        return true
    }
}

class DetachedTerminalManager {
    private var windows: [UUID: (window: NSWindow, delegate: DetachedWindowDelegate)] = [:]
    private unowned let runnerManager: RunnerManager

    init(runnerManager: RunnerManager) {
        self.runnerManager = runnerManager

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openTerminal(_:)),
            name: .openDetachedTerminal,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCommandDone(_:)),
            name: .commandDone,
            object: nil
        )
    }

    @objc private func openTerminal(_ notification: Notification) {
        guard let id = notification.userInfo?["id"] as? String,
              let uuid = UUID(uuidString: id),
              let runnerName = notification.userInfo?["runnerName"] as? String,
              let projectName = notification.userInfo?["projectName"] as? String else { return }

        let view = DetachedTerminalView(instanceId: uuid)
        let hostingController = NSHostingController(rootView: view.environmentObject(runnerManager))

        let window = NSWindow(contentViewController: hostingController)
        window.title = "\(runnerName) — \(projectName)"
        window.setContentSize(NSSize(width: 600, height: 400))
        window.center()
        window.isReleasedWhenClosed = false

        let delegate = DetachedWindowDelegate(instanceId: uuid, runnerManager: runnerManager)
        window.delegate = delegate

        windows[uuid] = (window, delegate)
        window.orderFrontRegardless()
        NSApplication.shared.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    @objc private func handleCommandDone(_ notification: Notification) {
        guard let id = notification.userInfo?["id"] as? String,
              let uuid = UUID(uuidString: id),
              let entry = windows[uuid] else { return }

        entry.window.close()
        windows.removeValue(forKey: uuid)
    }
}

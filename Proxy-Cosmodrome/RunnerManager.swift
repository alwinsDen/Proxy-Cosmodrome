import SwiftUI
import Combine
import AppKit
import UserNotifications

class RunnerManager: ObservableObject {
    @Published var runnerInstances: [RunnerInstance] = []
    @Published var selectedInstanceId: UUID?
    @Published var processStats: [UUID: String] = [:]

    private var cancellables: [Any] = []

    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }

        let center = NotificationCenter.default
        center.addObserver(
            forName: .commandOutput,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let id = notification.userInfo?["id"] as? String,
                  let output = notification.userInfo?["output"] as? String,
                  let uuid = UUID(uuidString: id),
                  let idx = self?.runnerInstances.firstIndex(where: { $0.id == uuid }) else { return }
            self?.runnerInstances[idx].output += output
        }
        center.addObserver(
            forName: .commandDone,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let id = notification.userInfo?["id"] as? String,
                  let uuid = UUID(uuidString: id),
                  let idx = self.runnerInstances.firstIndex(where: { $0.id == uuid }) else { return }
            self.runnerInstances[idx].isRunning = false
            self.runnerInstances[idx].exitCode = notification.userInfo?["exitCode"] as? Int
            self.processStats.removeValue(forKey: uuid)

            let instance = self.runnerInstances[idx]
            guard !NSApplication.shared.isActive else { return }
            let content = UNMutableNotificationContent()
            content.title = "\(instance.runnerName) finished"
            if let code = instance.exitCode {
                content.body = "\(instance.projectName) — exit code \(code)"
            } else {
                content.body = "\(instance.projectName)"
            }
            content.sound = .default
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            UNUserNotificationCenter.current().add(request)
        }
        center.addObserver(
            forName: .processStarted,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let id = notification.userInfo?["id"] as? String,
                  let uuid = UUID(uuidString: id),
                  let pid = notification.userInfo?["pid"] as? Int,
                  let idx = self?.runnerInstances.firstIndex(where: { $0.id == uuid }) else { return }
            self?.runnerInstances[idx].pid = pid
        }
    }

    func runRunner(_ runner: RunnerConfig, location: String, projectName: String, secrets: [SecretEntry], openDetached: Bool = false) {
        let relevantSecrets = secrets.filter { $0.runnerName.isEmpty || $0.runnerName == runner.name }
        let secretLog = relevantSecrets.map { "🔑 Injected secret: \($0.key)\n" }.joined()
        let envPrefix = relevantSecrets.map { "\($0.key)=\($0.value.shellEscaped)" }.joined(separator: " ")
        let enhancedCommand = envPrefix.isEmpty ? runner.command : "\(envPrefix) \(runner.command)"

        let instance = RunnerInstance(
            runnerName: runner.name,
            projectName: projectName,
            output: "\(secretLog)\(runner.command)\n\n",
            isRunning: true
        )
        runnerInstances.append(instance)
        selectedInstanceId = instance.id

        guard !location.isEmpty else {
            if let idx = runnerInstances.firstIndex(where: { $0.id == instance.id }) {
                runnerInstances[idx].output += "⚠ No project location set\n"
                runnerInstances[idx].isRunning = false
            }
            return
        }

        run_command_streaming(enhancedCommand, location, instance.id.uuidString)

        if openDetached {
            NotificationCenter.default.post(
                name: .openDetachedTerminal,
                object: nil,
                userInfo: [
                    "id": instance.id.uuidString,
                    "runnerName": runner.name,
                    "projectName": projectName,
                ]
            )
        }
    }

    func removeInstance(id: UUID) {
        if let idx = runnerInstances.firstIndex(where: { $0.id == id }), runnerInstances[idx].isRunning {
            kill_process(id.uuidString)
        }
        runnerInstances.removeAll { $0.id == id }
        processStats.removeValue(forKey: id)
        if selectedInstanceId == id {
            selectedInstanceId = runnerInstances.last?.id
        }
    }

    func stopRunner(id: UUID) {
        kill_process(id.uuidString)
    }

    func restartRunner(_ runner: RunnerConfig, location: String, projectName: String, secrets: [SecretEntry], openDetached: Bool = false) {
        let running = runnerInstances.filter {
            $0.runnerName == runner.name && $0.projectName == projectName && $0.isRunning
        }
        for instance in running {
            kill_process(instance.id.uuidString)
            runnerInstances.removeAll { $0.id == instance.id }
            processStats.removeValue(forKey: instance.id)
        }
        runRunner(runner, location: location, projectName: projectName, secrets: secrets, openDetached: openDetached)
    }

    func pollStats(for instanceId: UUID) {
        guard let instance = runnerInstances.first(where: { $0.id == instanceId }),
              let pid = instance.pid else { return }
        let stats = get_process_stats(UInt32(pid)).toString()
        DispatchQueue.main.async {
            self.processStats[instanceId] = stats
        }
    }
}

import SwiftUI
import Combine
import AppKit

class RunnerManager: ObservableObject {
    @Published var runnerInstances: [RunnerInstance] = []
    @Published var selectedInstanceId: UUID?

    private var cancellables: [Any] = []

    init() {
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
            guard let id = notification.userInfo?["id"] as? String,
                  let uuid = UUID(uuidString: id),
                  let idx = self?.runnerInstances.firstIndex(where: { $0.id == uuid }) else { return }
            self?.runnerInstances[idx].isRunning = false
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
        }
        runRunner(runner, location: location, projectName: projectName, secrets: secrets, openDetached: openDetached)
    }
}

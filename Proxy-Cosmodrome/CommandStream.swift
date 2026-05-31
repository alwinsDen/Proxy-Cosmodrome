import Foundation
import AppKit

extension Notification.Name {
    static let commandOutput = Notification.Name("commandOutput")
    static let commandDone = Notification.Name("commandDone")
    static let openEditProject = Notification.Name("openEditProject")
    static let projectConfigChanged = Notification.Name("projectConfigChanged")
    static let openDetachedTerminal = Notification.Name("openDetachedTerminal")
    static let processStarted = Notification.Name("processStarted")
}

func on_command_output(instance_id: RustString, output: RustString) {
    let id = instance_id.toString()
    let text = output.toString()
    DispatchQueue.main.async {
        NotificationCenter.default.post(
            name: .commandOutput,
            object: nil,
            userInfo: ["id": id, "output": text]
        )
    }
}

func on_command_done(instance_id: RustString, exit_code: Int32) {
    let id = instance_id.toString()
    DispatchQueue.main.async {
        NotificationCenter.default.post(
            name: .commandDone,
            object: nil,
            userInfo: ["id": id, "exitCode": Int(exit_code)]
        )
    }
}

func on_process_started(instance_id: RustString, pid: UInt32) {
    let id = instance_id.toString()
    DispatchQueue.main.async {
        NotificationCenter.default.post(
            name: .processStarted,
            object: nil,
            userInfo: ["id": id, "pid": Int(pid)]
        )
    }
}

import Foundation
import AppKit

extension Notification.Name {
    static let commandOutput = Notification.Name("commandOutput")
    static let commandDone = Notification.Name("commandDone")
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

func on_command_done(instance_id: RustString) {
    let id = instance_id.toString()
    DispatchQueue.main.async {
        NotificationCenter.default.post(
            name: .commandDone,
            object: nil,
            userInfo: ["id": id]
        )
    }
}

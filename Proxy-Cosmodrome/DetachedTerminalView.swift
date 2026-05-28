import SwiftUI

struct DetachedTerminalView: View {
    let instanceId: UUID
    @EnvironmentObject var runnerManager: RunnerManager

    var body: some View {
        if let instance = runnerManager.runnerInstances.first(where: { $0.id == instanceId }) {
            ScrollViewReader { proxy in
                ScrollView {
                    Text(instance.output)
                        .font(.system(size: 11, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(8)
                        .id("bottom")
                }
                .background(Color(NSColor.textBackgroundColor))
                .onChange(of: instance.output) { _, _ in
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }
}

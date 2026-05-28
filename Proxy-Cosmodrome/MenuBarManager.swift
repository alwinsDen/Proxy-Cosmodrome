import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var runnerManager: RunnerManager
    @State private var projects: [ProjectConfig] = []

    var body: some View {
        VStack(alignment: .leading) {
            Text("Proxy-Cosmodrome")
                .font(.headline)
                .padding(.horizontal, 8)
                .padding(.top, 4)

            Divider()

            if projects.isEmpty {
                Text("No projects configured")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            } else {
                ForEach(Array(projects.enumerated()), id: \.element.id) { _, project in
                    Menu(project.name) {
                        ForEach(Array(project.runners.enumerated()), id: \.element.id) { _, runner in
                            let running = runnerManager.runnerInstances.filter {
                                $0.runnerName == runner.name && $0.projectName == project.name && $0.isRunning
                            }
                            if running.isEmpty {
                                Button(runner.name) {
                                    runnerManager.runRunner(
                                        runner,
                                        location: project.location,
                                        projectName: project.name,
                                        secrets: project.secrets,
                                        openDetached: true
                                    )
                                }
                            } else {
                                ForEach(running) { instance in
                                    Button {
                                        runnerManager.stopRunner(id: instance.id)
                                    } label: {
                                        Label("Stop '\(runner.name)'", systemImage: "stop.circle")
                                    }
                                }
                                Button {
                                    runnerManager.restartRunner(
                                        runner,
                                        location: project.location,
                                        projectName: project.name,
                                        secrets: project.secrets,
                                        openDetached: true
                                    )
                                } label: {
                                    Label("Restart '\(runner.name)'", systemImage: "arrow.clockwise.circle")
                                }
                            }
                        }
                        Divider()
                        Button("Edit Config") {
                            NotificationCenter.default.post(
                                name: .openEditProject,
                                object: nil,
                                userInfo: ["projectID": project.id.uuidString]
                            )
                        }
                    }
                }
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .onAppear {
            loadProjects()
        }
        .onReceive(NotificationCenter.default.publisher(for: .projectConfigChanged)) { _ in
            loadProjects()
        }
    }

    private func loadProjects() {
        let raw = load_config().toString()
        guard !raw.hasPrefix("ERROR:"),
              let data = raw.data(using: .utf8),
              let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            projects = []
            return
        }

        guard let projectsArray = config["projects"] as? [[String: Any]] else {
            projects = []
            return
        }
        projects = projectsArray.compactMap { dict in
            guard let projectData = try? JSONSerialization.data(withJSONObject: dict),
                  let project = try? JSONDecoder().decode(ProjectConfig.self, from: projectData)
            else { return nil }
            return project
        }
    }
}

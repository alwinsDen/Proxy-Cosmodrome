//
//  ContentView.swift
//  Proxy-Cosmodrome
//
//  Created by Alwin T Varghese on 03/05/26.
//

import SwiftUI
import FontAwesomeSwiftUI

extension String {
    var shellEscaped: String {
        "'\(replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}

struct RunnerInstance: Identifiable, Equatable {
    let id = UUID()
    let runnerName: String
    let projectName: String
    var output: String
    var isRunning: Bool
}

struct MenuItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let subtitle: String
    let iconName: String
    let color: Color
}

struct MusicStyleListView: View {

    @State private var projects: [ProjectConfig] = []
    @State private var projectToEdit: ProjectConfig?
    @State private var runnerInstances: [RunnerInstance] = []
    @State private var selectedInstanceId: UUID?
    @State private var terminalHeight: CGFloat = 150

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    ForEach(Array(projects.enumerated()), id: \.element.id) { index, project in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(width: 24, alignment: .trailing)

                            VStack(alignment: .leading, spacing: 5)
                            {
                                Text(project.name)
                                    .font(.body)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(project.description)
                                    .font(.body)
                                    .lineLimit(1)
                                    .foregroundStyle(.secondary)
                            }.frame(maxWidth: 140)

                            HStack{
                                ProjectRunners(runners: project.runners, onRunRunner: { runRunner($0, in: project.location, projectName: project.name, secrets: project.secrets) }, onEdit: { projectToEdit = project }, onDelete: { deleteProject(project) })
                            }

                            Spacer()

                            Text(project.type)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .frame(maxWidth: 70, alignment: .leading)

                            Text(project.createdAt)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                                .frame(maxWidth: 100, alignment: .trailing)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    HStack(spacing: 12) {
                        Text("#")
                            .frame(width: 24, alignment: .trailing)
                        Text("Project Definition")
                            .frame(maxWidth: 140,alignment: .leading)
                        Text("Runners")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Type")
                            .frame(width: 70, alignment: .leading)
                        Text("created at")
                            .frame(maxWidth: 100, alignment: .trailing)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .listStyle(.inset)
            .navigationTitle("Application Manager")
            .onAppear(perform: loadProjects)
            .sheet(item: $projectToEdit) { project in
                EditProjectView(project: project) { updated in
                    updateProject(updated)
                }
            }

            if !runnerInstances.isEmpty {
                Rectangle()
                    .fill(.gray.opacity(0.2))
                    .frame(height: 5)
                    .overlay {
                        Image(systemName: "line.3.horizontal")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newHeight = terminalHeight - value.translation.height
                                terminalHeight = max(80, min(500, newHeight))
                            }
                    )
                    .onHover { inside in
                        if inside {
                            NSCursor.resizeUpDown.push()
                        } else {
                            NSCursor.pop()
                        }
                    }

                VStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 2) {
                            ForEach(runnerInstances) { instance in
                                HStack(spacing: 4) {
                                    Button {
                                        selectedInstanceId = instance.id
                                    } label: {
                                        Text(instance.runnerName)
                                            .font(.caption)
                                            .fontWeight(selectedInstanceId == instance.id ? .semibold : .regular)
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        runnerInstances.removeAll { $0.id == instance.id }
                                        if selectedInstanceId == instance.id {
                                            selectedInstanceId = runnerInstances.last?.id
                                        }
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(selectedInstanceId == instance.id ? Color.accentColor.opacity(0.15) : Color.clear)
                                .cornerRadius(4)
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                    }
                    .background(Color(NSColor.controlBackgroundColor))

                    if let selectedId = selectedInstanceId,
                       let instance = runnerInstances.first(where: { $0.id == selectedId }) {
                        ScrollViewReader { proxy in
                            ScrollView {
                                Text(instance.output)
                                    .font(.system(.caption, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                                    .padding(8)
                                    .id("bottom")
                            }
                            .frame(height: terminalHeight)
                            .background(Color(NSColor.textBackgroundColor))
                            .onChange(of: runnerInstances) { _, _ in
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                }
                .overlay(alignment: .top) { Divider() }
            }
        }
    }

    private func loadProjects() {
        let raw = load_config().toString()
        guard !raw.hasPrefix("ERROR:"),
              let data = raw.data(using: .utf8),
              let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let projectsArray = config["projects"] as? [[String: Any]] else {
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

    private func deleteProject(_ project: ProjectConfig) {
        projects.removeAll { $0.id == project.id }

        let raw = load_config().toString()
        guard !raw.hasPrefix("ERROR:"),
              let data = raw.data(using: .utf8),
              var config = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              var projectsArray = config["projects"] as? [[String: Any]] else { return }

        projectsArray.removeAll { dict in
            guard let idStr = dict["id"] as? String,
                  let uuid = UUID(uuidString: idStr) else { return false }
            return uuid == project.id
        }
        config["projects"] = projectsArray

        guard let finalData = try? JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted, .sortedKeys]),
              let finalJSON = String(data: finalData, encoding: .utf8) else { return }

        save_config(finalJSON)
    }

    private func updateProject(_ updated: ProjectConfig) {
        guard let index = projects.firstIndex(where: { $0.id == updated.id }) else { return }
        projects[index] = updated

        let raw = load_config().toString()
        guard !raw.hasPrefix("ERROR:"),
              let data = raw.data(using: .utf8),
              var config = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              var projectsArray = config["projects"] as? [[String: Any]] else { return }

        guard let projectData = try? JSONEncoder().encode(updated),
              let updatedDict = try? JSONSerialization.jsonObject(with: projectData) as? [String: Any] else { return }

        if let idx = projectsArray.firstIndex(where: { dict in
            guard let idStr = dict["id"] as? String,
                  let uuid = UUID(uuidString: idStr) else { return false }
            return uuid == updated.id
        }) {
            projectsArray[idx] = updatedDict
        }

        config["projects"] = projectsArray

        guard let finalData = try? JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted, .sortedKeys]),
              let finalJSON = String(data: finalData, encoding: .utf8) else { return }

        save_config(finalJSON)
    }

    private func runRunner(_ runner: RunnerConfig, in location: String, projectName: String, secrets: [SecretEntry]) {
        let relevantSecrets = secrets.filter { $0.runnerName.isEmpty || $0.runnerName == runner.name }
        let secretLog = relevantSecrets.map { "🔑 Injected secret: \($0.key)\n" }.joined()
        let envPrefix = relevantSecrets.map { "\($0.key)=\($0.value.shellEscaped)" }.joined(separator: " ")
        let enhancedCommand = envPrefix.isEmpty ? runner.command : "\(envPrefix) \(runner.command)"

        let instance = RunnerInstance(
            runnerName: runner.name,
            projectName: projectName,
            output: "\(secretLog)▶ [\(runner.name)] \(runner.command)\n\n",
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

        let instanceId = instance.id
        DispatchQueue.global().async {
            let output = run_command(enhancedCommand, location).toString()
            DispatchQueue.main.async {
                if let idx = runnerInstances.firstIndex(where: { $0.id == instanceId }) {
                    runnerInstances[idx].output += output
                    if !output.hasSuffix("\n") { runnerInstances[idx].output += "\n" }
                    runnerInstances[idx].isRunning = false
                }
            }
        }
    }
}

struct ContentView: View {
    
    var buildInfo: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let _build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        
        #if DEBUG
        let type = "debug"
        #else
        let type = "release"
        #endif
        
        return "v\(version)-\(type)"
    }

    private let menuItems: [MenuItem] = [
        MenuItem(name: "Apps", subtitle: "Manage applications", iconName: "square.grid.2x2.fill", color: .blue),
        MenuItem(name: "Server", subtitle: "Server configuration", iconName: "server.rack", color: .green),
        MenuItem(name: "Docker", subtitle: "Container management", iconName: "shippingbox.fill", color: .orange),
        MenuItem(name: "Edit Configuration", subtitle: "Amend run settings", iconName: "apple.meditate", color: .red)
    ]

    @State private var selectedItem: MenuItem.ID?

    @State private var showConfigEditor = false
    @State private var showCreateNew = false
    @State private var configJSON: String = "{}"
    @State private var projectRefreshID = UUID()

    private func loadConfig() {
        let result = load_config().toString()
        if result.hasPrefix("ERROR:") {
            configJSON = "{}"
        } else {
            configJSON = result
        }
    }

    private var selectedMenuItem: MenuItem? {
        menuItems.first { $0.id == selectedItem }
    }

    var body: some View {
        NavigationSplitView {
            List(menuItems, selection: $selectedItem) { item in
                HStack(spacing: 12) {
                    Image(systemName: item.iconName)
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(item.color.gradient, in: RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.body)
                            .fontWeight(.medium)
                        Text(item.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Menu")
            .frame(idealWidth: 150)
            Text(buildInfo)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(10)
        } detail: {
            if selectedMenuItem?.name == "Edit Configuration" {
                Color.clear
                    .onAppear { showConfigEditor = true }
            } else if selectedMenuItem?.name == "Apps" || selectedItem == nil {
                MusicStyleListView()
                    .id(projectRefreshID)
            } else {
                ContentUnavailableView("Select an item", systemImage: "sidebar.left", description: Text("Choose an item from the sidebar."))
            }
        }
        .navigationTitle("Proxy Cosmodrome Manager")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateNew = true
                } label: {
                    Text("Create New")
                    Image(systemName: "plus")
                        .font(.system(size: 10))
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {} label: {
                    Text("star")
                    Image(systemName: "star")
                        .font(.system(size: 10))
                }
            }
        }
        .sheet(isPresented: $showConfigEditor) {
            ConfigEditorView(jsonText: $configJSON)
                .onDisappear {
                    selectedItem = menuItems.first?.id
                }
        }
        .onAppear(perform: loadConfig)
        .sheet(isPresented: $showCreateNew) {
            CreateNewProjectView()
                .onDisappear {
                    loadConfig()
                    projectRefreshID = UUID()
                }
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 800, height: 600)
}

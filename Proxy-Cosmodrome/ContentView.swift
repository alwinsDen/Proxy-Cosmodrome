//
//  ContentView.swift
//  Proxy-Cosmodrome
//
//  Created by Alwin T Varghese on 03/05/26.
//

import SwiftUI
import FontAwesomeSwiftUI

struct MenuItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let subtitle: String
    let iconName: String
    let color: Color
}

struct MusicStyleListView: View {

    @State private var projects: [ProjectConfig] = []
    @State private var showEditSheet = false
    @State private var projectToEdit: ProjectConfig?

    var body: some View {
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
                            ProjectRunners(runners: project.runners, onEdit: { projectToEdit = project; showEditSheet = true }, onDelete: { deleteProject(project) })
                        }

                        Spacer()

                        Text(project.type)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .frame(maxWidth: 70, alignment: .leading)
//                            .background(.yellow)

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
//                        .background(Color(.red))
                    Text("Type")
                        .frame(width: 70, alignment: .leading)
//                        .background(Color(.blue))
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
        .sheet(isPresented: $showEditSheet) {
            if let project = projectToEdit {
                EditProjectView(project: project) { updated in
                    updateProject(updated)
                }
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

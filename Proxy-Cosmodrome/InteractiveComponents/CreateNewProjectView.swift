import SwiftUI

// MARK: - Data Models

struct RunnerConfig: Identifiable, Codable {
    var id = UUID()
    var name: String
    var command: String
}

struct SecretEntry: Identifiable, Codable {
    var id = UUID()
    var key: String
    var value: String
    var runnerName: String = ""

    enum CodingKeys: String, CodingKey {
        case key, value, runnerName
    }

    init(id: UUID = UUID(), key: String, value: String, runnerName: String = "") {
        self.id = id
        self.key = key
        self.value = value
        self.runnerName = runnerName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        value = try container.decode(String.self, forKey: .value)
        runnerName = try container.decodeIfPresent(String.self, forKey: .runnerName) ?? ""
    }
}

struct ProjectConfig: Identifiable, Codable {
    var id = UUID()
    var name: String
    var description: String
    var githubURL: String
    var category: String = "App"
    var type: String
    var location: String = ""
    var createdAt: String
    var secrets: [SecretEntry]
    var runners: [RunnerConfig]

    enum CodingKeys: String, CodingKey {
        case id, name, description, type, secrets, runners, category, location
        case githubURL = "github_url"
        case createdAt = "created_at"
    }

    init(id: UUID = UUID(), name: String, description: String, githubURL: String, category: String = "App", type: String, location: String = "", createdAt: String, secrets: [SecretEntry], runners: [RunnerConfig]) {
        self.id = id
        self.name = name
        self.description = description
        self.githubURL = githubURL
        self.category = category
        self.type = type
        self.location = location
        self.createdAt = createdAt
        self.secrets = secrets
        self.runners = runners
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        githubURL = try container.decodeIfPresent(String.self, forKey: .githubURL) ?? ""
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? "App"
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        location = try container.decodeIfPresent(String.self, forKey: .location) ?? ""
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        secrets = try container.decodeIfPresent([SecretEntry].self, forKey: .secrets) ?? []
        runners = try container.decodeIfPresent([RunnerConfig].self, forKey: .runners) ?? []
    }
}

// MARK: - Project Category

enum ProjectCategory: String, CaseIterable {
    case app = "App"
    case server = "Server"
    case docker = "Docker"
}

// MARK: - Create New Project View

struct CreateNewProjectView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: ProjectCategory = .app
    @State private var projectName = ""
    @State private var githubURL = ""
    @State private var description = ""
    @State private var type = ""
    @State private var location = ""
    @State private var secrets: [SecretEntry] = []
    @State private var runners: [RunnerConfig] = []

    @State private var toastMessage: String?
    @State private var showToast = false

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M/dd HH:mm"
        return f
    }()

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                HStack {
                    Text("Create New Project")
                        .font(.headline)
                    Spacer()
                    Button("Cancel", action: { dismiss() })
                        .keyboardShortcut(.escape)
                    Button("Save", action: save)
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.return)
                }
                .padding()

                Form {
                    Section {
                        Picker("Project Type", selection: $selectedCategory) {
                            ForEach(ProjectCategory.allCases, id: \.self) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    if selectedCategory == .app {
                        appForm
                    } else {
                        workInProgress
                    }
                }
                .formStyle(.grouped)
            }
            .frame(width: 560, height: 480)

            if showToast, let message = toastMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.white)
                    Text(message)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.9))
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showToast = false
                        }
                    }
                }
            }
        }
        .animation(.easeOut(duration: 0.2), value: showToast)
    }

    // MARK: - App Form

    private var appForm: some View {
        Group {
            Section("Project Details") {
                TextField("Project Name", text: $projectName)
                TextField("GitHub URL", text: $githubURL)
                TextField("Description", text: $description)
                TextField("Type", text: $type)
            }

            Section("Location") {
                HStack {
                    TextField("Project Folder", text: $location)
                    Button("Browse...", action: selectFolder)
                }
            }

            Section("Runners") {
                if runners.isEmpty {
                    Text("No runners configured")
                        .foregroundStyle(.secondary)
                }
                ForEach($runners) { $runner in
                    HStack(spacing: 8) {
                        TextField("Name", text: $runner.name)
                            .frame(minWidth: 100)
                        TextField("Command", text: $runner.command)
                            .frame(minWidth: 180)
                        Button {
                            runners.removeAll { $0.id == runner.id }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                        .help("Remove runner")
                    }
                }
                Button {
                    runners.append(RunnerConfig(name: "", command: ""))
                } label: {
                    Label("Add Runner", systemImage: "plus.circle")
                }
            }

            Section("Secrets") {
                if secrets.isEmpty {
                    Text("No secrets added")
                        .foregroundStyle(.secondary)
                }
                ForEach($secrets) { $secret in
                    HStack(spacing: 8) {
                        TextField("Key", text: $secret.key)
                            .frame(minWidth: 100)
                        TextField("Value", text: $secret.value)
                            .frame(minWidth: 100)
                        Picker("Runner", selection: $secret.runnerName) {
                            Text("All Runners").tag("")
                            ForEach(runners.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }) { runner in
                                Text(runner.name).tag(runner.name)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(minWidth: 90)
                        Button {
                            secrets.removeAll { $0.id == secret.id }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                        .help("Remove secret")
                    }
                }
                Button {
                    secrets.append(SecretEntry(key: "", value: ""))
                } label: {
                    Label("Add Secret", systemImage: "plus.circle")
                }
            }
        }
    }

    // MARK: - Work In Progress

    private var workInProgress: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "hammer.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Work in progress")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("\(selectedCategory.rawValue) project support is coming soon.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }

    // MARK: - Folder Selection

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.begin { response in
            if response == .OK, let url = panel.url {
                location = url.path
            }
        }
    }

    // MARK: - Save

    private func save() {
        guard selectedCategory == .app else {
            toastMessage = "\(selectedCategory.rawValue) projects are not yet supported"
            withAnimation(.easeOut(duration: 0.2)) { showToast = true }
            return
        }

        let trimmedName = projectName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            toastMessage = "Project name is required"
            withAnimation(.easeOut(duration: 0.2)) { showToast = true }
            return
        }

        let trimmedURL = githubURL.trimmingCharacters(in: .whitespaces)
        guard !trimmedURL.isEmpty else {
            toastMessage = "GitHub URL is required"
            withAnimation(.easeOut(duration: 0.2)) { showToast = true }
            return
        }

        let trimmedType = type.trimmingCharacters(in: .whitespaces)
        guard !trimmedType.isEmpty else {
            toastMessage = "Type is required"
            withAnimation(.easeOut(duration: 0.2)) { showToast = true }
            return
        }

        let createdAt = dateFormatter.string(from: Date())

        let project = ProjectConfig(
            name: trimmedName,
            description: description.trimmingCharacters(in: .whitespaces),
            githubURL: trimmedURL,
            category: selectedCategory.rawValue,
            type: trimmedType,
            location: location.trimmingCharacters(in: .whitespaces),
            createdAt: createdAt,
            secrets: secrets.filter { !$0.key.trimmingCharacters(in: .whitespaces).isEmpty },
            runners: runners.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        )

        let existingJSON = load_config().toString()
        var configDict: [String: Any]

        if existingJSON.hasPrefix("ERROR:") {
            configDict = ["base_config_location": ""]
        } else if let data = existingJSON.data(using: .utf8),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            configDict = dict
        } else {
            configDict = ["base_config_location": ""]
        }

        var projects = configDict["projects"] as? [[String: Any]] ?? []

        guard let projectData = try? JSONEncoder().encode(project),
              let projectDict = try? JSONSerialization.jsonObject(with: projectData) as? [String: Any] else {
            toastMessage = "Failed to serialize project"
            withAnimation(.easeOut(duration: 0.2)) { showToast = true }
            return
        }

        projects.append(projectDict)
        configDict["projects"] = projects

        guard let finalData = try? JSONSerialization.data(withJSONObject: configDict, options: [.prettyPrinted, .sortedKeys]),
              let finalJSON = String(data: finalData, encoding: .utf8) else {
            toastMessage = "Failed to serialize config"
            withAnimation(.easeOut(duration: 0.2)) { showToast = true }
            return
        }

        guard save_config(finalJSON) else {
            toastMessage = "Failed to save config"
            withAnimation(.easeOut(duration: 0.2)) { showToast = true }
            return
        }

        dismiss()
    }
}

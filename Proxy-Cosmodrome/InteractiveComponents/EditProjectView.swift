import SwiftUI

struct EditProjectView: View {
    let project: ProjectConfig
    let onSave: (ProjectConfig) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var runners: [RunnerConfig]
    @State private var secrets: [SecretEntry]
    @State private var location: String
    @State private var githubURL: String
    @State private var description: String
    @State private var type: String

    @State private var toastMessage: String?
    @State private var showToast = false

    init(project: ProjectConfig, onSave: @escaping (ProjectConfig) -> Void) {
        self.project = project
        self.onSave = onSave
        _runners = State(initialValue: project.runners)
        _secrets = State(initialValue: project.secrets)
        _location = State(initialValue: project.location)
        _githubURL = State(initialValue: project.githubURL)
        _description = State(initialValue: project.description)
        _type = State(initialValue: project.type)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                HStack {
                    Text("Edit Project")
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
                    Section("Project Details") {
                        LabeledContent("Name", value: project.name)
                        TextField("GitHub URL", text: $githubURL)
                            .textFieldStyle(.roundedBorder)
                        TextField("Description", text: $description)
                            .textFieldStyle(.roundedBorder)
                        TextField("Type", text: $type)
                            .textFieldStyle(.roundedBorder)
                    }

                    Section("Location") {
                        HStack {
                            TextField("Project Folder", text: $location)
                                .textFieldStyle(.roundedBorder)
                            Button("Browse...", action: selectFolder)
                        }
                    }

                    Section("Runners") {
                        if runners.isEmpty {
                            Text("No runners configured")
                                .foregroundStyle(.secondary)
                        }
                        ForEach($runners) { $runner in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    TextField("Name", text: $runner.name)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(minWidth: 100)
                                    TextField("Command", text: $runner.command)
                                        .textFieldStyle(.roundedBorder)
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
                                iconPicker(for: $runner)
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
                                    .textFieldStyle(.roundedBorder)
                                    .frame(minWidth: 100)
                                TextField("Value", text: $secret.value)
                                    .textFieldStyle(.roundedBorder)
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

    private func iconPicker(for runner: Binding<RunnerConfig>) -> some View {
        HStack(spacing: 10) {
            ForEach(RunnerConfig.availableIcons, id: \.self) { iconName in
                Button {
                    runner.wrappedValue.icon = iconName
                } label: {
                    Image(systemName: iconName)
                        .font(.system(size: 16))
                        .foregroundStyle(runner.wrappedValue.icon == iconName ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)
                .help(RunnerConfig.iconLabels[iconName] ?? iconName)
            }
        }
    }

    private func save() {
        let updated = ProjectConfig(
            id: project.id,
            name: project.name,
            description: description.trimmingCharacters(in: .whitespaces),
            githubURL: githubURL.trimmingCharacters(in: .whitespaces),
            category: project.category,
            type: type.trimmingCharacters(in: .whitespaces),
            location: location.trimmingCharacters(in: .whitespaces),
            createdAt: project.createdAt,
            secrets: secrets.filter { !$0.key.trimmingCharacters(in: .whitespaces).isEmpty },
            runners: runners.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        )
        onSave(updated)
        dismiss()
    }
}

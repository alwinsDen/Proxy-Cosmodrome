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
    var pid: Int? = nil
    var exitCode: Int? = nil
}

struct MenuItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let subtitle: String
    let iconName: String
    let color: Color
}

struct MusicStyleListView: View {

    @EnvironmentObject var runnerManager: RunnerManager

    @State private var projects: [ProjectConfig] = []
    @State private var projectToEdit: ProjectConfig?
    @State private var terminalHeight: CGFloat = 150
    @State private var terminalFontSize: CGFloat = 11
    @State private var searchText: String = ""
    @State private var statsTimer: Timer?

    private var matchCount: Int {
        guard !searchText.isEmpty,
              let id = runnerManager.selectedInstanceId,
              let instance = runnerManager.runnerInstances.first(where: { $0.id == id })
        else { return 0 }
        let text = instance.output
        var count = 0
        var start = text.startIndex
        while start < text.endIndex {
            guard let r = text.range(of: searchText, options: .caseInsensitive, range: start..<text.endIndex) else { break }
            count += 1
            start = r.upperBound
        }
        return count
    }

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
                                ProjectRunners(runners: project.runners, onRunRunner: { runnerManager.runRunner($0, location: project.location, projectName: project.name, secrets: project.secrets) }, onRestartRunner: { runnerManager.restartRunner($0, location: project.location, projectName: project.name, secrets: project.secrets) }, isRunnerRunning: { runner in runnerManager.runnerInstances.contains(where: { $0.runnerName == runner.name && $0.projectName == project.name && $0.isRunning }) }, onEdit: { projectToEdit = project }, onDelete: { deleteProject(project) })
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
            .onReceive(NotificationCenter.default.publisher(for: .openEditProject)) { notification in
                guard let idStr = notification.userInfo?["projectID"] as? String,
                      let uuid = UUID(uuidString: idStr),
                      let project = projects.first(where: { $0.id == uuid }) else { return }
                projectToEdit = project
            }
            .sheet(item: $projectToEdit) { project in
                EditProjectView(project: project) { updated in
                    updateProject(updated)
                }
            }

            if !runnerManager.runnerInstances.isEmpty {
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
                        HStack(spacing: 4) {
                            ForEach(runnerManager.runnerInstances) { instance in
                                Button {
                                    runnerManager.selectedInstanceId = instance.id
                                } label: {
                                    HStack(spacing: 5) {
                                        Circle()
                                            .fill(instance.isRunning ? Color.green : Color.gray)
                                            .frame(width: 7, height: 7)
                                        Text(instance.runnerName)
                                            .font(.caption)
                                            .fontWeight(runnerManager.selectedInstanceId == instance.id ? .semibold : .regular)
                                        Button {
                                            runnerManager.removeInstance(id: instance.id)
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                }
                                .buttonBorderShape(.roundedRectangle(radius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(.gray, lineWidth: 1)
                                )
                                .background {
                                    if runnerManager.selectedInstanceId == instance.id {
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(Color(NSColor.windowBackgroundColor))
                                            .shadow(color: .black.opacity(0.08), radius: 1, y: 0.5)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                    }
                    .background(Color(NSColor.controlBackgroundColor))

                    if let selectedId = runnerManager.selectedInstanceId,
                       let instance = runnerManager.runnerInstances.first(where: { $0.id == selectedId }) {
                        HStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("Find in output…", text: $searchText)
                                .textFieldStyle(.plain)
                                .font(.caption)
                                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in }
                            if !searchText.isEmpty {
                                Text("\(matchCount) matches")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(NSColor.controlBackgroundColor))
                        .overlay(alignment: .bottom) { Divider() }

                        ScrollViewReader { proxy in
                            ScrollView {
                                if searchText.isEmpty {
                                    Text(attributedOutput(instance.output).0)
                                        .font(.system(size: terminalFontSize, design: .monospaced))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .textSelection(.enabled)
                                        .padding(8)
                                        .id("bottom")
                                } else {
                                    Text(highlightedOutput(instance.output, search: searchText))
                                        .font(.system(size: terminalFontSize, design: .monospaced))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .textSelection(.enabled)
                                        .padding(8)
                                        .id("bottom")
                                }
                            }
                            .frame(height: terminalHeight)
                            .background(Color(NSColor.textBackgroundColor))
                            .onChange(of: runnerManager.runnerInstances) { _, _ in
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                            .overlay(alignment: .bottomTrailing) {
                                VStack(alignment: .trailing, spacing: 4) {
                                    // if let selId = runnerManager.selectedInstanceId,
                                    //    let statsStr = runnerManager.processStats[selId],
                                    //    let data = statsStr.data(using: .utf8),
                                    //    let stats = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                                    //     HStack(spacing: 8) {
                                    //         if let cpu = stats["cpu"] {
                                    //             Text("CPU \(cpu)%")
                                    //                 .font(.caption2)
                                    //                 .foregroundStyle(.secondary)
                                    //                 .monospacedDigit()
                                    //         }
                                    //         if let mem = stats["mem"] {
                                    //             Text("MEM \(mem)%")
                                    //                 .font(.caption2)
                                    //                 .foregroundStyle(.secondary)
                                    //                 .monospacedDigit()
                                    //         }
                                    //         if let uptime = stats["uptime"] {
                                    //             Text(uptime)
                                    //                 .font(.caption2)
                                    //                 .foregroundStyle(.secondary)
                                    //                 .monospacedDigit()
                                    //         }
                                    //     }
                                    //     .padding(.horizontal, 8)
                                    //     .padding(.vertical, 4)
                                    //     .background(.ultraThinMaterial)
                                    //     .clipShape(RoundedRectangle(cornerRadius: 6))
                                    // }

                                    HStack(spacing: 4) {
                                        Button {
                                            let newSize = max(6, terminalFontSize - 1)
                                            terminalFontSize = newSize
                                            saveTerminalFontSize(newSize)
                                        } label: {
                                            Image(systemName: "minus.magnifyingglass")
                                                .font(.system(size: 15))
                                                .frame(width: 22, height: 22)
                                                .foregroundStyle(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                        .help("Zoom out")

                                        Button {
                                            let newSize = min(24, terminalFontSize + 1)
                                            terminalFontSize = newSize
                                            saveTerminalFontSize(newSize)
                                        } label: {
                                            Image(systemName: "plus.magnifyingglass")
                                                .font(.system(size: 15))
                                                .frame(width: 22, height: 22)
                                                .foregroundStyle(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                        .help("Zoom in")
                                    }
                                    .padding(6)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .padding(12)
                            }
                        }
                    }
                }
                .overlay(alignment: .top) { Divider() }
            }
        }
        .onDisappear {
            statsTimer?.invalidate()
            statsTimer = nil
        }
        .onChange(of: runnerManager.selectedInstanceId) { _, newId in
            updateStatsTimer(for: newId)
        }
        .onChange(of: runnerManager.runnerInstances) { _, _ in
            updateStatsTimer(for: runnerManager.selectedInstanceId)
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

        if let fontSize = config["terminal_font_size"] as? Double {
            terminalFontSize = max(6, min(24, CGFloat(fontSize)))
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

    private func saveTerminalFontSize(_ size: CGFloat) {
        let raw = load_config().toString()
        guard !raw.hasPrefix("ERROR:"),
              let data = raw.data(using: .utf8),
              var config = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        config["terminal_font_size"] = Double(size)
        guard let finalData = try? JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted, .sortedKeys]),
              let finalJSON = String(data: finalData, encoding: .utf8) else { return }
        save_config(finalJSON)
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
        NotificationCenter.default.post(name: .projectConfigChanged, object: nil)
    }

    private func updateStatsTimer(for instanceId: UUID?) {
        statsTimer?.invalidate()
        statsTimer = nil
        guard let id = instanceId,
              let instance = runnerManager.runnerInstances.first(where: { $0.id == id }),
              instance.isRunning,
              instance.pid != nil else { return }
        statsTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak runnerManager] _ in
            runnerManager?.pollStats(for: id)
        }
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
        NotificationCenter.default.post(name: .projectConfigChanged, object: nil)
    }

    // MARK: - ANSI Parsing

    private static func standardColor(_ index: UInt8) -> Color {
        switch index % 8 {
        case 0: return .black
        case 1: return .red
        case 2: return .green
        case 3: return .yellow
        case 4: return .blue
        case 5: return Color(red: 1, green: 0, blue: 1)
        case 6: return .cyan
        case 7: return .white
        default: return .black
        }
    }

    private static func brightColor(_ index: UInt8) -> Color {
        switch index % 8 {
        case 0: return Color(white: 0.5)
        case 1: return Color(red: 1, green: 0.4, blue: 0.4)
        case 2: return Color(red: 0.4, green: 1, blue: 0.4)
        case 3: return Color(red: 1, green: 1, blue: 0.4)
        case 4: return Color(red: 0.4, green: 0.4, blue: 1)
        case 5: return Color(red: 1, green: 0.4, blue: 1)
        case 6: return Color(red: 0.4, green: 1, blue: 1)
        case 7: return .white
        default: return .white
        }
    }

    private static func color256(_ index: UInt8) -> Color {
        switch index {
        case 0...7: return standardColor(index)
        case 8...15: return brightColor(index - 8)
        case 16...231:
            let n = Int(index - 16)
            let r = n / 36
            let g = (n / 6) % 6
            let b = n % 6
            return Color(
                red: Double(r * 51) / 255,
                green: Double(g * 51) / 255,
                blue: Double(b * 51) / 255
            )
        case 232...255:
            let gray = Double(index - 232) * 10 + 8
            return Color(white: gray / 255)
        default: return .black
        }
    }

    private func applySGR(_ params: String, bold: inout Bool, italic: inout Bool, underline: inout Bool, fg: inout Color?, bg: inout Color?) {
        guard !params.isEmpty else {
            bold = false; italic = false; underline = false; fg = nil; bg = nil
            return
        }
        let codes = params.split(separator: ";", omittingEmptySubsequences: false).map(String.init)
        var i = 0
        while i < codes.count {
            guard let code = Int(codes[i]) else { i += 1; continue }
            i += 1
            switch code {
            case 0: bold = false; italic = false; underline = false; fg = nil; bg = nil
            case 1: bold = true
            case 3: italic = true
            case 4: underline = true
            case 22: bold = false
            case 23: italic = false
            case 24: underline = false
            case 30...37: fg = Self.standardColor(UInt8(code - 30))
            case 38:
                guard i < codes.count else { break }
                if codes[i] == "5" {
                    i += 1
                    guard i < codes.count, let n = Int(codes[i]) else { break }
                    fg = Self.color256(UInt8(n))
                    i += 1
                } else if codes[i] == "2" {
                    i += 1
                    let r = i < codes.count ? Int(codes[i]) ?? 0 : 0; i += 1
                    let g = i < codes.count ? Int(codes[i]) ?? 0 : 0; i += 1
                    let b = i < codes.count ? Int(codes[i]) ?? 0 : 0; i += 1
                    fg = Color(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
                } else {
                    i += 1
                }
            case 39: fg = nil
            case 40...47: bg = Self.standardColor(UInt8(code - 40))
            case 48:
                guard i < codes.count else { break }
                if codes[i] == "5" {
                    i += 1
                    guard i < codes.count, let n = Int(codes[i]) else { break }
                    bg = Self.color256(UInt8(n))
                    i += 1
                } else if codes[i] == "2" {
                    i += 1
                    let r = i < codes.count ? Int(codes[i]) ?? 0 : 0; i += 1
                    let g = i < codes.count ? Int(codes[i]) ?? 0 : 0; i += 1
                    let b = i < codes.count ? Int(codes[i]) ?? 0 : 0; i += 1
                    bg = Color(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
                } else {
                    i += 1
                }
            case 49: bg = nil
            case 90...97: fg = Self.brightColor(UInt8(code - 90))
            case 100...107: bg = Self.brightColor(UInt8(code - 100))
            default: break
            }
        }
    }

    private func buildAttributed(_ text: String, bold: Bool, italic: Bool, underline: Bool, fg: Color?, bg: Color?) -> AttributedString {
        var attr = AttributedString(text)
        var font = Font.system(size: terminalFontSize, design: .monospaced)
        if bold { font = font.bold() }
        if italic { font = font.italic() }
        attr.font = font
        if underline { attr.underlineStyle = .single }
        if let fg { attr.foregroundColor = fg }
        if let bg { attr.backgroundColor = bg }
        return attr
    }

    private func attributedOutput(_ output: String) -> (AttributedString, String) {
        var result = AttributedString()
        var plainText = ""
        guard let pattern = try? NSRegularExpression(pattern: "\u{1B}\\[([0-9;]*)m") else {
            let attr = AttributedString(output)
            return (attr, output)
        }
        let nsRange = NSRange(output.startIndex..., in: output)
        var lastEnd = output.startIndex

        var bold = false
        var italic = false
        var underline = false
        var fg: Color?
        var bg: Color?

        pattern.enumerateMatches(in: output, range: nsRange) { match, _, _ in
            guard let match, let matchRange = Range(match.range, in: output) else { return }
            if lastEnd < matchRange.lowerBound {
                let segment = String(output[lastEnd..<matchRange.lowerBound])
                result.append(buildAttributed(segment, bold: bold, italic: italic, underline: underline, fg: fg, bg: bg))
                plainText += segment
            }
            let params = match.range(at: 1)
            let paramsStr = params.location != NSNotFound ? String(output[Range(params, in: output)!]) : ""
            applySGR(paramsStr, bold: &bold, italic: &italic, underline: &underline, fg: &fg, bg: &bg)
            lastEnd = matchRange.upperBound
        }

        if lastEnd < output.endIndex {
            let segment = String(output[lastEnd...])
            result.append(buildAttributed(segment, bold: bold, italic: italic, underline: underline, fg: fg, bg: bg))
            plainText += segment
        }

        return (result, plainText)
    }

    private func highlightedOutput(_ output: String, search: String) -> AttributedString {
        guard !search.isEmpty else { return attributedOutput(output).0 }
        var pair = attributedOutput(output)
        var attributed = pair.0
        let plainText = pair.1
        let searchLower = search.lowercased()
        let plainLower = plainText.lowercased()
        var searchStart = plainLower.startIndex
        while searchStart < plainLower.endIndex {
            guard let found = plainLower[searchStart...].range(of: searchLower) else { break }
            if let attrRange = Range<AttributedString.Index>(NSRange(found, in: plainText), in: attributed) {
                attributed[attrRange].backgroundColor = Color.yellow
            }
            searchStart = found.upperBound
        }
        return attributed
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

    private static let menuItems: [MenuItem] = [
        MenuItem(name: "Apps", subtitle: "Manage applications", iconName: "square.grid.2x2.fill", color: .blue),
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
        Self.menuItems.first { $0.id == selectedItem }
    }

    var body: some View {
        NavigationSplitView {
            List(Self.menuItems, selection: $selectedItem) { item in
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
                Button {
                    test_trigger_click()
                } label: {
                    Text("star")
                    Image(systemName: "star")
                        .font(.system(size: 10))
                }
            }
        }
        .sheet(isPresented: $showConfigEditor) {
            ConfigEditorView(jsonText: $configJSON)
                .onDisappear {
                    selectedItem = Self.menuItems.first?.id
                }
        }
        .onAppear(perform: loadConfig)
        .onReceive(NotificationCenter.default.publisher(for: .openEditProject)) { _ in
            selectedItem = Self.menuItems.first?.id
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        .sheet(isPresented: $showCreateNew) {
            CreateNewProjectView()
                .onDisappear {
                    loadConfig()
                    projectRefreshID = UUID()
                    NotificationCenter.default.post(name: .projectConfigChanged, object: nil)
                }
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 800, height: 600)
}

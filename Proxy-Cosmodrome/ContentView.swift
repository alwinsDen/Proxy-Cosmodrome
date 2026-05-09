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

struct Project: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let type: String
    let created_at: String
}

struct MusicStyleListView: View {

    private let projects: [Project] = [
        Project(title: "SAAS web app", description: "weekend test01", type: "react", created_at: "3:20"),
        Project(title: "Claude code", description: "test 02", type: "react", created_at: "3:23", ),
        Project(title: "Proxy-test", description: "simple web app", type: "react", created_at: "2:54", ),
    ]

    var body: some View {
        List {
            Section {
                ForEach(Array(projects.enumerated()), id: \.element.id) { index, project in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(width: 24, alignment: .trailing)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(.clear)
                            .frame(width: 40, height: 40)
                            .overlay {
                                Image(systemName: "music.note")
                                    .foregroundStyle(.white)
                                    .font(.caption)
                            }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(project.title)
                                .font(.body)
                                .lineLimit(1)
                            Text(project.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Text(project.type)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .frame(maxWidth: 140, alignment: .leading)

                        Text(project.created_at)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .padding(.vertical, 2)
                }
            } header: {
                HStack(spacing: 12) {
                    Text("#")
                        .frame(width: 24, alignment: .trailing)
                    Text("Project Definition")
                        .padding(.leading, 52)
                    Spacer()
                    Text("Type")
                        .frame(maxWidth: 115, alignment: .leading)
                    Text("created at")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .listStyle(.inset)
        .navigationTitle("Application Manager")
    }
}

struct ContentView: View {

    private let menuItems: [MenuItem] = [
        MenuItem(name: "Apps", subtitle: "Manage applications", iconName: "square.grid.2x2.fill", color: .blue),
        MenuItem(name: "Server", subtitle: "Server configuration", iconName: "server.rack", color: .green),
        MenuItem(name: "Docker", subtitle: "Container management", iconName: "shippingbox.fill", color: .orange)
    ]

    @State private var selectedItem: MenuItem.ID?

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
        } detail: {
            if selectedMenuItem?.name == "Apps" || selectedItem == nil {
                MusicStyleListView()
            } else {
                ContentUnavailableView("Select an item", systemImage: "sidebar.left", description: Text("Choose an item from the sidebar."))
            }
        }
        .navigationTitle("Proxy Cosmodrome Manager")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {} label: {
                    Text("Onboard app")
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
    }
}

#Preview {
    ContentView()
}

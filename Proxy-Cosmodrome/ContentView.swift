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

struct ContentView: View {

    private let menuItems: [MenuItem] = [
        MenuItem(name: "Apps", subtitle: "Manage applications", iconName: "square.grid.2x2.fill", color: .blue),
        MenuItem(name: "Server", subtitle: "Server configuration", iconName: "server.rack", color: .green),
        MenuItem(name: "Docker", subtitle: "Container management", iconName: "shippingbox.fill", color: .orange)
    ]

    @State private var selectedItem: MenuItem.ID?

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
            if let selectedItem, let item = menuItems.first(where: { $0.id == selectedItem }) {
                Text("Selected: \(item.name)")
            } else {
                Text("Select an item")
            }
        }
        .navigationTitle("Proxy Cosmodrome Manager")
        .toolbar {
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

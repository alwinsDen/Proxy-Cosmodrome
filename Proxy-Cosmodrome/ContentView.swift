//
//  ContentView.swift
//  Proxy-Cosmodrome
//
//  Created by Alwin T Varghese on 03/05/26.
//

import SwiftUI
import FontAwesomeSwiftUI

struct ContentView: View {
    
    @State private var selectedItem : String = "Apps"
    let selectedItemsBinding = ["Apps","Server","Docker"]
    
    var body: some View {
        NavigationSplitView {
            List(selectedItemsBinding, id: \.self, selection: $selectedItem) { item in
                Text(item)
            }
            .navigationTitle("Menu")
        } detail: {
            Text("Select an item")
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

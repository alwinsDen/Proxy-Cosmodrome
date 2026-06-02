//
//  Proxy_CosmodromeApp.swift
//  Proxy-Cosmodrome
//
//  Created by Alwin T Varghese on 03/05/26.
//

import SwiftUI

@main
struct Proxy_CosmodromeApp: App {
    @StateObject private var runnerManager = RunnerManager()
    @State private var terminalManager: DetachedTerminalManager?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(runnerManager)
                .preferredColorScheme(.dark)
                .onAppear {
                    if terminalManager == nil {
                        terminalManager = DetachedTerminalManager(runnerManager: runnerManager)
                    }
                }
        }

        MenuBarExtra {
            MenuBarView()
                .environmentObject(runnerManager)
                .preferredColorScheme(.dark)
        } label: {
            Image("MenuBarIcon")
        }
        .menuBarExtraStyle(.menu)
    }
}

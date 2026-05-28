//
//  ProjectRunners.swift
//  Proxy-Cosmodrome
//
//  Created by Alwin T Varghese on 12/05/26.
//
import SwiftUI

struct ProjectRunners : View {
    var runners: [RunnerConfig] = []
    var onRunRunner: ((RunnerConfig) -> Void)?
    var onRestartRunner: ((RunnerConfig) -> Void)?
    var isRunnerRunning: ((RunnerConfig) -> Bool)?
    var onEdit: (() -> Void)?
    var onDelete: () -> Void

    @State private var showDeleteConfirmation = false
    @State private var hoveredRunnerId: UUID?

    private let runnerColors: [Color] = [
        .blue, .green, .orange, .purple, .pink, .teal,
        .indigo, .mint, .cyan, .yellow, .brown, .red
    ]

    var body : some View {
        HStack {
            ForEach(Array(runners.enumerated()), id: \.element.id) { index, runner in
                let isRunning = isRunnerRunning?(runner) ?? false
                Button {
                    if isRunning {
                        onRestartRunner?(runner)
                    } else {
                        onRunRunner?(runner)
                    }
                } label: {
                    Image(systemName: isRunning ? "arrow.clockwise.circle" : runner.icon)
                        .font(.system(size: 24))
                        .contentShape(Circle())
                        .foregroundStyle(runnerColors[index % runnerColors.count])
                }
                .buttonStyle(.plain)
                .popover(isPresented: Binding(
                    get: { hoveredRunnerId == runner.id },
                    set: { if !$0 { hoveredRunnerId = nil } }
                )) {
                    Text(runner.name)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                }
                .onHover { hovering in
                    hoveredRunnerId = hovering ? runner.id : nil
                }
            }
            Spacer()
            Button{}label: {
                Image(systemName: "newspaper.circle")
                    .font(.system(size:24))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            Button { onEdit?() } label: {
                Image(systemName: "square.and.pencil.circle")
                    .font(.system(size:24))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            Button {
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash.circle")
                    .font(.system(size:24))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .confirmationDialog(
            "Delete Project",
            isPresented: $showDeleteConfirmation
        ) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this project? This action cannot be undone.")
        }
    }
}

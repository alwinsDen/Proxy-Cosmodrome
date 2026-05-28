//
//  ProjectRunners.swift
//  Proxy-Cosmodrome
//
//  Created by Alwin T Varghese on 12/05/26.
//
import SwiftUI

struct ProjectRunners : View {
    var runners: [RunnerConfig] = []
    var onEdit: (() -> Void)?
    var onDelete: () -> Void

    @State private var showDeleteConfirmation = false

    private let runnerColors: [Color] = [
        .blue, .green, .orange, .purple, .pink, .teal,
        .indigo, .mint, .cyan, .yellow, .brown, .red
    ]

    var body : some View {
        HStack {
            ForEach(Array(runners.enumerated()), id: \.element.id) { index, runner in
                Button {} label: {
                    Image(systemName: "play.circle")
                        .font(.system(size: 24))
                        .contentShape(Circle())
                        .foregroundStyle(runnerColors[index % runnerColors.count])
                }
                .buttonStyle(.plain)
                .help(runner.name)
            }
            Spacer()
            Button{}label: {
                Image(systemName: "newspaper.circle")
                    .font(.system(size:24))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            Button{}label: {
                Image(systemName: "eye.slash.circle")
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

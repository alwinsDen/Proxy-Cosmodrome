import SwiftUI

struct ConfigEditorView: View {
    @Binding var jsonText: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Configuration Editor")
                    .font(.headline)
                Spacer()
                Button("Cancel", action: { dismiss() })
                    .keyboardShortcut(.escape)
                Button("Save", action: { dismiss() })
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return)
            }
            .padding()

            TextEditor(text: $jsonText)
                .font(.system(.body, design: .monospaced))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.bottom)
        }
        .frame(width: 560, height: 380)
    }
}

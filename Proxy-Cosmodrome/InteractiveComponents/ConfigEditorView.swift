import SwiftUI

struct ConfigEditorView: View {
    @Binding var jsonText: String
    @Environment(\.dismiss) private var dismiss
    @State private var toastMessage: String?
    @State private var showToast = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                HStack {
                    Text("Configuration Editor")
                        .font(.headline)
                Spacer()
                Button("Format", action: format)
                Button("Cancel", action: { dismiss() })
                    .keyboardShortcut(.escape)
                Button("Save", action: save)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return)
                }
                .padding()

                CodeEditorView(text: $jsonText)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            .frame(width: 560, height: 380)

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

    private func format() {
        let sanitized = jsonText
            .replacingOccurrences(of: "\u{201C}", with: "\"")
            .replacingOccurrences(of: "\u{201D}", with: "\"")
        guard let data = sanitized.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let prettyString = String(data: pretty, encoding: .utf8)
        else {
            toastMessage = "Invalid JSON format"
            withAnimation(.easeOut(duration: 0.2)) {
                showToast = true
            }
            return
        }
        jsonText = prettyString
    }

    private func save() {
        let sanitized = jsonText
            .replacingOccurrences(of: "\u{201C}", with: "\"")
            .replacingOccurrences(of: "\u{201D}", with: "\"")
        jsonText = sanitized

        guard let data = sanitized.data(using: .utf8),
              (try? JSONSerialization.jsonObject(with: data)) != nil
        else {
            toastMessage = "Invalid JSON format"
            withAnimation(.easeOut(duration: 0.2)) {
                showToast = true
            }
            return
        }

        guard save_config(sanitized) else {
            toastMessage = "Failed to save config"
            withAnimation(.easeOut(duration: 0.2)) {
                showToast = true
            }
            return
        }

        dismiss()
    }
}

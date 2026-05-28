import SwiftUI
import AppKit

class CodeEditorCoordinator: NSObject, NSTextViewDelegate {
    var parent: CodeEditorView

    init(_ parent: CodeEditorView) {
        self.parent = parent
    }

    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else { return }
        parent.text = textView.string
    }

    func textView(_ textView: NSTextView, shouldChangeTextIn range: NSRange, replacementString string: String?) -> Bool {
        guard let string else { return true }

        let paired: [Character: Character] = ["\"": "\"", "{": "}", "[": "]"]

        if string.count == 1, let char = string.first, let close = paired[char] {
            let selected = textView.string

            if range.length == 0, range.location < selected.count {
                let charAfter = selected[selected.index(selected.startIndex, offsetBy: range.location)]
                if charAfter == close {
                    textView.replaceCharacters(in: range, with: "")
                    textView.setSelectedRange(NSRange(location: range.location, length: 0))
                    return false
                }
            }

            let insertion = "\(char)\(close)"
            textView.replaceCharacters(in: range, with: insertion)
            textView.setSelectedRange(NSRange(location: range.location + 1, length: 0))
            return false
        }

        if string.isEmpty && range.length == 1 {
            let selected = textView.string
            guard range.location < selected.count else { return true }
            let index = selected.index(selected.startIndex, offsetBy: range.location)
            let char = selected[index]

            if let close = paired[char], range.location + 1 < selected.count {
                let nextIndex = selected.index(after: index)
                if selected[nextIndex] == close {
                    textView.replaceCharacters(in: NSRange(location: range.location, length: 2), with: "")
                    return false
                }
            }
        }

        return true
    }
}

struct CodeEditorView: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> CodeEditorCoordinator {
        CodeEditorCoordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true
        textView.string = text
        textView.allowsUndo = true

        scrollView.documentView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
    }
}

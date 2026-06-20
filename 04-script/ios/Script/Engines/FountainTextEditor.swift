import SwiftUI
import UIKit

struct FountainTextEditor: View {
    @Binding var text: String
    let fontSize: Double
    let autoFormat: Bool

    var body: some View {
        VStack(spacing: 0) {
            FountainUITextViewRepresentable(text: $text, fontSize: fontSize, autoFormat: autoFormat)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct FountainUITextViewRepresentable: UIViewRepresentable {
    @Binding var text: String
    let fontSize: Double
    let autoFormat: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.font = UIFont(name: "Courier", size: CGFloat(fontSize)) ?? UIFont.monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular)
        tv.backgroundColor = .clear
        tv.textColor = UIColor.label
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .none
        tv.smartQuotesType = .no
        tv.smartDashesType = .no
        tv.spellCheckingType = .no
        tv.textContainerInset = UIEdgeInsets(top: 16, left: 24, bottom: 16, right: 24)
        tv.alwaysBounceVertical = true

        // Add format toolbar above keyboard
        let toolbar = makeFormatToolbar(textView: tv, coordinator: context.coordinator)
        tv.inputAccessoryView = toolbar

        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            let selectedRange = uiView.selectedRange
            uiView.text = text
            let nsText = text as NSString
            if selectedRange.location <= nsText.length {
                uiView.selectedRange = selectedRange
            }
        }
        uiView.font = UIFont(name: "Courier", size: CGFloat(fontSize)) ?? UIFont.monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular)
    }

    private func makeFormatToolbar(textView: UITextView, coordinator: Coordinator) -> UIView {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let intExt = UIBarButtonItem(title: "INT./EXT.", style: .plain, target: coordinator, action: #selector(Coordinator.insertSceneHeading))
        let action = UIBarButtonItem(title: "ACTION", style: .plain, target: coordinator, action: #selector(Coordinator.insertAction))
        let character = UIBarButtonItem(title: "CHARACTER", style: .plain, target: coordinator, action: #selector(Coordinator.insertCharacter))
        let dialogue = UIBarButtonItem(title: "DIALOGUE", style: .plain, target: coordinator, action: #selector(Coordinator.insertDialogue))
        let paren = UIBarButtonItem(title: "PAREN", style: .plain, target: coordinator, action: #selector(Coordinator.insertParenthetical))
        let transition = UIBarButtonItem(title: "TRANS", style: .plain, target: coordinator, action: #selector(Coordinator.insertTransition))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Done", style: .done, target: coordinator, action: #selector(Coordinator.dismissKeyboard))

        // Style buttons
        let font = UIFont(name: "Courier", size: 11) ?? UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(red: 0.957, green: 0.635, blue: 0.380, alpha: 1)
        ]
        for item in [intExt, action, character, dialogue, paren, transition] {
            item.setTitleTextAttributes(attrs, for: .normal)
        }

        toolbar.items = [intExt, action, character, dialogue, paren, transition, flexSpace, done]
        coordinator.textView = textView
        return toolbar
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: FountainUITextViewRepresentable
        weak var textView: UITextView?

        init(_ parent: FountainUITextViewRepresentable) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }

        @objc func insertSceneHeading() {
            guard let tv = textView else { return }
            let selectedRange = tv.selectedRange
            let text = tv.text as NSString
            // Find start of current line
            let lineRange = text.lineRange(for: NSRange(location: selectedRange.location, length: 0))
            let currentLine = text.substring(with: lineRange).trimmingCharacters(in: .whitespacesAndNewlines)

            if currentLine.isEmpty {
                let insertion = "INT.  - DAY\n"
                if let startPos = tv.position(from: tv.beginningOfDocument, offset: lineRange.location),
                   let endPos = tv.position(from: tv.beginningOfDocument, offset: lineRange.location + lineRange.length),
                   let range = tv.textRange(from: startPos, to: endPos) {
                    tv.replace(range, withText: insertion)
                } else {
                    tv.replace(tv.selectedTextRange!, withText: insertion)
                }
                // Position cursor between INT. and - DAY
                if let pos = tv.position(from: tv.beginningOfDocument, offset: lineRange.location + 5) {
                    tv.selectedTextRange = tv.textRange(from: pos, to: pos)
                }
            } else {
                // Make current line a scene heading
                let upper = currentLine.uppercased()
                if let startPos = tv.position(from: tv.beginningOfDocument, offset: lineRange.location),
                   let endPos = tv.position(from: tv.beginningOfDocument, offset: lineRange.location + currentLine.count),
                   let range = tv.textRange(from: startPos, to: endPos) {
                    tv.replace(range, withText: upper)
                }
            }
            parent.text = tv.text
        }

        @objc func insertAction() {
            guard let tv = textView else { return }
            // Ensure empty line then start action paragraph
            insertNewlineIfNeeded(tv: tv)
            parent.text = tv.text
        }

        @objc func insertCharacter() {
            guard let tv = textView else { return }
            let selectedRange = tv.selectedRange
            let text = tv.text as NSString
            let lineRange = text.lineRange(for: NSRange(location: selectedRange.location, length: 0))
            let currentLine = text.substring(with: lineRange).trimmingCharacters(in: .whitespacesAndNewlines)

            if !currentLine.isEmpty {
                // Uppercase current line
                let upper = currentLine.uppercased()
                if let startPos = tv.position(from: tv.beginningOfDocument, offset: lineRange.location),
                   let endPos = tv.position(from: tv.beginningOfDocument, offset: lineRange.location + currentLine.count),
                   let range = tv.textRange(from: startPos, to: endPos) {
                    tv.replace(range, withText: upper)
                }
            }
            parent.text = tv.text
        }

        @objc func insertDialogue() {
            guard let tv = textView else { return }
            insertNewlineIfNeeded(tv: tv)
            parent.text = tv.text
        }

        @objc func insertParenthetical() {
            guard let tv = textView else { return }
            let curPos = tv.selectedRange.location
            let insertion = "()\n"
            if let pos = tv.position(from: tv.beginningOfDocument, offset: curPos),
               let range = tv.textRange(from: pos, to: pos) {
                tv.replace(range, withText: insertion)
                // Position cursor inside parens
                if let insidePos = tv.position(from: tv.beginningOfDocument, offset: curPos + 1) {
                    tv.selectedTextRange = tv.textRange(from: insidePos, to: insidePos)
                }
            }
            parent.text = tv.text
        }

        @objc func insertTransition() {
            guard let tv = textView else { return }
            let curPos = tv.selectedRange.location
            let insertion = "\nCUT TO:\n"
            if let pos = tv.position(from: tv.beginningOfDocument, offset: curPos),
               let range = tv.textRange(from: pos, to: pos) {
                tv.replace(range, withText: insertion)
            }
            parent.text = tv.text
        }

        @objc func dismissKeyboard() {
            textView?.resignFirstResponder()
        }

        private func insertNewlineIfNeeded(tv: UITextView) {
            let curPos = tv.selectedRange.location
            let text = tv.text as NSString
            if curPos > 0 {
                let prevChar = text.substring(with: NSRange(location: curPos - 1, length: 1))
                if prevChar != "\n" {
                    if let pos = tv.position(from: tv.beginningOfDocument, offset: curPos),
                       let range = tv.textRange(from: pos, to: pos) {
                        tv.replace(range, withText: "\n")
                    }
                }
            }
        }
    }
}

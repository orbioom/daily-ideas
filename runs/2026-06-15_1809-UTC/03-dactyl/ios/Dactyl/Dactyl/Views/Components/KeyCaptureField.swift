import SwiftUI
import UIKit

/// A custom first-responder `UIView` that conforms to `UIKeyInput`. It raises the system
/// keyboard and forwards each inserted character and each backspace to closures. We capture
/// insert + delete directly (rather than diffing a bound String) so errors and backspaces are
/// counted correctly.
final class KeyCaptureView: UIView, UIKeyInput {
    var onInsert: ((Character) -> Void)?
    var onDelete: (() -> Void)?

    // MARK: First responder
    override var canBecomeFirstResponder: Bool { true }

    // MARK: UIKeyInput
    var hasText: Bool { true }   // We always allow backspace handling.

    func insertText(_ text: String) {
        // A single keystroke can deliver one (or, rarely, several) characters.
        for ch in text {
            onInsert?(ch)
        }
    }

    func deleteBackward() {
        onDelete?()
    }

    // MARK: UITextInputTraits (configure the keyboard)
    var keyboardType: UIKeyboardType = .default
    var autocorrectionType: UITextAutocorrectionType = .no
    var autocapitalizationType: UITextAutocapitalizationType = .none
    var spellCheckingType: UITextSpellCheckingType = .no
    var smartQuotesType: UITextSmartQuotesType = .no
    var smartDashesType: UITextSmartDashesType = .no
    var smartInsertDeleteType: UITextSmartInsertDeleteType = .no
    var returnKeyType: UIReturnKeyType = .default
    var enablesReturnKeyAutomatically: Bool = false
}

/// SwiftUI wrapper around `KeyCaptureView`. Binding-driven focus keeps it crash-proof:
/// when `isActive` is true it becomes first responder (raising the keyboard); when false it
/// resigns. Tapping anywhere over it also re-raises the keyboard.
struct KeyCaptureField: UIViewRepresentable {
    @Binding var isActive: Bool
    var onInsert: (Character) -> Void
    var onDelete: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        view.onInsert = onInsert
        view.onDelete = onDelete

        // A tap re-focuses the field if the keyboard was dismissed.
        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleTap(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        context.coordinator.view = view
        return view
    }

    func updateUIView(_ uiView: KeyCaptureView, context: Context) {
        // Keep closures fresh (SwiftUI may recreate them each render).
        uiView.onInsert = onInsert
        uiView.onDelete = onDelete
        context.coordinator.view = uiView

        // Drive focus from the binding on the next runloop tick to avoid
        // "modifying state during view update" warnings.
        DispatchQueue.main.async {
            if isActive {
                if !uiView.isFirstResponder { uiView.becomeFirstResponder() }
            } else {
                if uiView.isFirstResponder { uiView.resignFirstResponder() }
            }
        }
    }

    final class Coordinator {
        weak var view: KeyCaptureView?

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view, !view.isFirstResponder else { return }
            view.becomeFirstResponder()
        }
    }
}

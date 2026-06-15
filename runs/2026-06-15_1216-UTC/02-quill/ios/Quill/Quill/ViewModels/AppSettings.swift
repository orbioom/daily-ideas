import SwiftUI

/// App-wide preferences persisted via `@AppStorage`. Exposed as an
/// `ObservableObject` so views can observe and mutate them.
@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("appearance") var appearanceRaw: String = AppearanceMode.system.rawValue
    @AppStorage("defaultTemplate") var defaultTemplateRaw: String = PaperTemplate.ruled.rawValue
    @AppStorage("inputPolicy") var inputPolicyRaw: String = InputPolicy.anyInput.rawValue
    /// Default pen color stored as a hex string.
    @AppStorage("defaultPenColorHex") var defaultPenColorHex: String = "#1E1B2E"

    // Typed accessors -------------------------------------------------------

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var defaultTemplate: PaperTemplate {
        get { PaperTemplate(rawValue: defaultTemplateRaw) ?? .ruled }
        set { defaultTemplateRaw = newValue.rawValue }
    }

    var inputPolicy: InputPolicy {
        get { InputPolicy(rawValue: inputPolicyRaw) ?? .anyInput }
        set { inputPolicyRaw = newValue.rawValue }
    }
}

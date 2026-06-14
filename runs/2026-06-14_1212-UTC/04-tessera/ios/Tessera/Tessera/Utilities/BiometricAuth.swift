import Foundation
import LocalAuthentication

/// Thin wrapper over LocalAuthentication for the app-lock gate.
enum BiometricAuth {

    /// Human label for the device's biometry, for UI copy.
    static func biometryName() -> String {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return "device passcode"
        }
    }

    /// Whether the device can authenticate (biometrics or passcode).
    static func canEvaluate() -> Bool {
        let context = LAContext()
        var error: NSError?
        // deviceOwnerAuthentication falls back to passcode if biometry is unavailable.
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    /// Prompt the user to unlock. Calls back on the main thread with success/failure.
    static func authenticate(reason: String, completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        context.localizedFallbackTitle = "Enter Passcode"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // No biometrics or passcode set up — fail open is unsafe, fail closed
            // would lock the user out forever, so we report failure and let the UI
            // offer a retry / explain. (In practice a device with a passcode always
            // can evaluate.)
            DispatchQueue.main.async { completion(false) }
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
            DispatchQueue.main.async { completion(success) }
        }
    }
}

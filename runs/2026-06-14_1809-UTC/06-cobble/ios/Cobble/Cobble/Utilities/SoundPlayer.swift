import AudioToolbox

/// Tiny system-sound effects for place / clear / game-over. Gated by the user's sound
/// preference at every call site. Uses AudioToolbox system sounds so no bundled assets
/// are required and there is nothing to crash on.
final class SoundPlayer {
    static let shared = SoundPlayer()
    private init() {}

    enum Effect {
        case place
        case clear
        case gameOver

        /// A pleasant built-in system sound id for each effect.
        var systemID: SystemSoundID {
            switch self {
            case .place: return 1104     // light keyboard tick
            case .clear: return 1057     // tweet / positive
            case .gameOver: return 1053  // soft descending
            }
        }
    }

    func play(_ effect: Effect, enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(effect.systemID)
    }
}

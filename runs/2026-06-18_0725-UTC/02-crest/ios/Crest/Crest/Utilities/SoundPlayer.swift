import AVFoundation

/// Plays short system feedback sounds for card draws / clears.
/// Uses AudioServices system sounds so no bundled audio assets are required.
/// Gated by the caller passing the current draw-sound setting.
enum SoundPlayer {
    /// A light click for drawing from stock / placing a card.
    static func draw(enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(1104) // keyboard tap-style click
    }

    /// A brighter chime for winning.
    static func win(enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(1025) // anticipate / positive
    }
}

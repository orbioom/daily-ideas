import Foundation

/// Per-track live mixer state (mute + volume). Not persisted with the grid;
/// it's a performance control that resets per session, but it's Codable so
/// it can travel with a Pattern if desired.
struct TrackState: Equatable, Codable {
    var muted: Bool = false
    var volume: Double = 0.85   // 0...1

    static func defaults() -> [TrackState] {
        Array(repeating: TrackState(), count: StepGrid.rows)
    }
}

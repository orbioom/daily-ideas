import Foundation
import SwiftData

/// A named passage or skill within a piece — "bars 32–40 LH", "the trill", a scale.
/// Carries its own tempo journey (current → target) and a 0–5 mastery rating.
/// Cascade-deleted with its owning piece.
@Model
final class PracticeSpot {
    var id: UUID
    var name: String
    /// Ordering within the piece (stable, user-arrangeable by creation order).
    var order: Int
    /// Where the passage sits today, in BPM. 0 means "not set yet".
    var currentTempo: Int
    /// Where the passage wants to land, in BPM. 0 means "not set".
    var targetTempo: Int
    /// Self-assessed mastery, 0 (untouched) – 5 (performance-ready).
    var mastery: Int
    var notes: String
    var createdAt: Date

    /// Owning piece. Optional so SwiftData can manage the inverse relationship.
    var piece: Piece?

    init(id: UUID = UUID(),
         name: String,
         order: Int = 0,
         currentTempo: Int = 0,
         targetTempo: Int = 0,
         mastery: Int = 0,
         notes: String = "",
         createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.order = order
        self.currentTempo = currentTempo
        self.targetTempo = targetTempo
        self.mastery = mastery
        self.notes = notes
        self.createdAt = createdAt
    }

    // MARK: - Derived

    /// Fraction of the tempo journey covered, 0…1. Nil when there's nothing to measure.
    var tempoProgress: Double? {
        guard targetTempo >= Tempo.min, currentTempo > 0 else { return nil }
        if currentTempo >= targetTempo { return 1 }
        return min(1, max(0, Double(currentTempo) / Double(targetTempo)))
    }

    /// Mastery clamped into the supported 0…5 band for safe display.
    var clampedMastery: Int { min(5, max(0, mastery)) }

    /// Whether this spot has reached its target tempo.
    var atTarget: Bool {
        targetTempo >= Tempo.min && currentTempo >= targetTempo
    }
}

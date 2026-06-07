import Foundation
import SwiftData

/// A song with its chord chart, broken into ordered sections.
@Model
final class Song {
    var id: UUID = UUID()
    var title: String = ""
    var artist: String = ""
    var key: String = "C"
    var bpm: Int = 0
    var capo: Int = 0
    var timeSignature: String = "4/4"
    var notes: String = ""
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \Section.song)
    var sections: [Section] = []

    init(title: String, artist: String = "", key: String = "C", bpm: Int = 0,
         capo: Int = 0, timeSignature: String = "4/4", notes: String = "") {
        self.id = UUID()
        self.title = title
        self.artist = artist
        self.key = key
        self.bpm = bpm
        self.capo = capo
        self.timeSignature = timeSignature
        self.notes = notes
        self.createdAt = Date()
    }

    var orderedSections: [Section] { sections.sorted { $0.order < $1.order } }

    /// Rough duration estimate from bpm and total bar count (very approximate).
    var estimatedSeconds: Int {
        guard bpm > 0 else { return 0 }
        let beatsPerBar = Int(timeSignature.split(separator: "/").first.flatMap { Int($0) } ?? 4)
        let totalBars = orderedSections.map { $0.estimatedBars }.reduce(0, +)
        let beats = totalBars * beatsPerBar
        return Int(Double(beats) / Double(bpm) * 60.0)
    }

    var allChords: [String] {
        var seen = Set<String>(); var out: [String] = []
        for s in orderedSections {
            for c in ChordEngine.chords(in: s.content) where !seen.contains(c) { seen.insert(c); out.append(c) }
        }
        return out
    }
}

/// One labelled block of a chart (Verse, Chorus, Bridge…).
@Model
final class Section {
    var id: UUID = UUID()
    var name: String = ""
    var order: Int = 0
    /// ChordPro-style content with inline `[chords]`.
    var content: String = ""
    var song: Song?

    init(name: String, order: Int, content: String = "") {
        self.id = UUID()
        self.name = name
        self.order = order
        self.content = content
    }

    /// Estimates bars from the number of chord changes (one bar per chord, min by lines).
    var estimatedBars: Int {
        let chordCount = ChordEngine.chords(in: content).count
        let lineCount = content.split(separator: "\n", omittingEmptySubsequences: true).count
        return max(chordCount, lineCount, 1)
    }
}

/// An ordered performance set referencing songs with per-slot transpose/capo.
@Model
final class Setlist {
    var id: UUID = UUID()
    var name: String = ""
    var venue: String = ""
    var date: Date = Date()
    var notes: String = ""
    @Relationship(deleteRule: .cascade, inverse: \SetlistItem.setlist)
    var items: [SetlistItem] = []

    init(name: String, venue: String = "", date: Date = Date(), notes: String = "") {
        self.id = UUID()
        self.name = name
        self.venue = venue
        self.date = date
        self.notes = notes
    }

    var orderedItems: [SetlistItem] { items.sorted { $0.order < $1.order } }
    var estimatedSeconds: Int { orderedItems.compactMap { $0.song?.estimatedSeconds }.reduce(0, +) }
}

/// A slot in a setlist: a song plus the transpose/capo to play it at tonight.
@Model
final class SetlistItem {
    var id: UUID = UUID()
    var order: Int = 0
    var transpose: Int = 0
    var capo: Int = 0
    var note: String = ""
    var song: Song?
    var setlist: Setlist?

    init(order: Int, song: Song?, transpose: Int = 0, capo: Int = 0, note: String = "") {
        self.id = UUID()
        self.order = order
        self.song = song
        self.transpose = transpose
        self.capo = capo
        self.note = note
    }

    /// The sounding key after this slot's transpose.
    var performKey: String {
        guard let song else { return "" }
        return ChordEngine.transposedKey(song.key, semitones: transpose)
    }
}

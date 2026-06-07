import SwiftUI

/// Renders a ChordPro-style chart with chords sitting above the lyric they fall
/// on. Applies live transpose and optional Nashville-number display.
struct ChartView: View {
    let content: String
    var semitones: Int = 0
    var preferFlats: Bool = false
    var nashville: Bool = false
    var key: String = "C"

    private struct Segment: Identifiable {
        let id = UUID()
        let chord: String?
        let lyric: String
    }

    private var lines: [[Segment]] {
        content.components(separatedBy: "\n").map { parse(line: $0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, segs in
                if segs.isEmpty || (segs.count == 1 && segs[0].chord == nil && segs[0].lyric.isEmpty) {
                    Color.clear.frame(height: 8)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .bottom, spacing: 0) {
                            ForEach(segs) { seg in
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(displayChord(seg.chord) ?? " ")
                                        .font(Brand.mono(13, weight: .bold))
                                        .foregroundStyle(seg.chord == nil ? .clear : Brand.live)
                                    Text(seg.lyric.isEmpty ? " " : seg.lyric)
                                        .font(.system(size: 16))
                                        .foregroundStyle(Brand.text)
                                }
                                .fixedSize()
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func displayChord(_ chord: String?) -> String? {
        guard let chord else { return nil }
        if nashville { return ChordEngine.nashville(for: chord, key: ChordEngine.transposedKey(key, semitones: semitones)) }
        return ChordEngine.transposeChord(chord, semitones: semitones, preferFlats: preferFlats)
    }

    /// Splits a line into (chord?, following lyric) segments.
    private func parse(line: String) -> [Segment] {
        var segs: [Segment] = []
        var i = line.startIndex
        var pendingChord: String? = nil
        var buffer = ""
        func flush() {
            if pendingChord != nil || !buffer.isEmpty {
                segs.append(Segment(chord: pendingChord, lyric: buffer))
            }
            pendingChord = nil; buffer = ""
        }
        while i < line.endIndex {
            if line[i] == "[", let close = line[i...].firstIndex(of: "]") {
                flush()
                pendingChord = String(line[line.index(after: i)..<close]).trimmingCharacters(in: .whitespaces)
                i = line.index(after: close)
            } else {
                buffer.append(line[i]); i = line.index(after: i)
            }
        }
        flush()
        return segs
    }
}

import SwiftUI

/// Standalone transposer, Nashville converter, and capo calculator — no song
/// required. Type chords separated by spaces.
struct ToolsView: View {
    @State private var input = "G D Em C"
    @State private var fromKey = "G"
    @State private var toKey = "B"
    @State private var manualSemitones = 0
    @State private var useKeys = true

    private let keys = ["C","Db","D","Eb","E","F","Gb","G","Ab","A","Bb","B",
                        "Am","Bm","Cm","Dm","Em","Fm","Gm"]

    private var semitones: Int {
        useKeys ? ChordEngine.semitones(from: fromKey, to: toKey) : manualSemitones
    }
    private var soundingKey: String {
        useKeys ? toKey : ChordEngine.transposedKey(fromKey, semitones: manualSemitones)
    }
    private var preferFlats: Bool { ChordEngine.preferFlats(forKey: soundingKey) }

    private var tokens: [String] {
        input.split(whereSeparator: { $0 == " " || $0 == "|" || $0 == "\n" || $0 == "," }).map(String.init)
    }
    private var transposed: [String] {
        tokens.map { ChordEngine.transposeChord($0, semitones: semitones, preferFlats: preferFlats) }
    }
    private var nashville: [String] {
        tokens.map { ChordEngine.nashville(for: $0, key: fromKey) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    inputCard
                    modeCard
                    resultCard
                    capoCard
                }
                .padding()
            }
            .navigationTitle("Tools")
            .background(Brand.pageBackground)
        }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Chords")
            TextField("e.g. G D Em C", text: $input, axis: .vertical)
                .font(Brand.mono(16, weight: .medium))
                .foregroundStyle(Brand.text)
                .lineLimit(1...4)
            Text("Separate chords with spaces, commas or bars.")
                .font(.caption).foregroundStyle(Brand.text3)
        }
        .glassCard()
    }

    private var modeCard: some View {
        VStack(spacing: 14) {
            Picker("Mode", selection: $useKeys) {
                Text("By key").tag(true)
                Text("By semitones").tag(false)
            }.pickerStyle(.segmented)
            if useKeys {
                HStack {
                    keyPicker("From", $fromKey)
                    Image(systemName: "arrow.right").foregroundStyle(Brand.text3)
                    keyPicker("To", $toKey)
                }
                Text("Shift: \(semitones >= 0 ? "+" : "")\(semitones) semitones")
                    .font(.caption).foregroundStyle(Brand.text2)
            } else {
                HStack {
                    keyPicker("Original key", $fromKey)
                    Spacer()
                    Stepper("\(manualSemitones >= 0 ? "+" : "")\(manualSemitones)", value: $manualSemitones, in: -11...11)
                        .fixedSize()
                }
            }
        }
        .glassCard()
    }

    private func keyPicker(_ label: String, _ binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(Brand.text3)
            Picker(label, selection: binding) { ForEach(keys, id: \.self) { Text($0).tag($0) } }
                .tint(Brand.text).labelsHidden()
        }
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Transposed → \(soundingKey)")
            FlowChips(items: transposed.isEmpty ? ["—"] : transposed, color: Brand.live)
            Divider().overlay(Brand.hairline)
            Text("Nashville (in \(fromKey))").font(.caption).foregroundStyle(Brand.text3)
            FlowChips(items: nashville.isEmpty ? ["—"] : nashville, color: Brand.info)
        }
        .glassCard()
    }

    private var capoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Capo options for \(soundingKey)")
            ForEach(ChordEngine.capoSuggestions(forSoundingKey: soundingKey)) { s in
                HStack {
                    Text(s.capo == 0 ? "No capo" : "Capo \(s.capo)")
                        .font(.subheadline).foregroundStyle(Brand.text)
                    Spacer()
                    Text("play \(s.shapeKey)").font(Brand.mono(14)).foregroundStyle(Brand.text2)
                    if s.isOpenFriendly {
                        Image(systemName: "star.fill").font(.caption2).foregroundStyle(Brand.magic)
                            .accessibilityLabel("open friendly")
                    }
                }
                if s.capo < 7 { Divider().overlay(Brand.hairline) }
            }
            Text("★ = open-string-friendly shapes")
                .font(.caption2).foregroundStyle(Brand.text3)
        }
        .glassCard()
    }
}

/// A simple wrapping row of chord chips.
struct FlowChips: View {
    let items: [String]
    var color: Color = Brand.text
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Text(item)
                    .font(Brand.mono(15, weight: .semibold))
                    .foregroundStyle(color)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

/// A minimal flow layout that wraps its children.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[CGSize]] = [[]]
        var x: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, !rows[rows.count - 1].isEmpty {
                rows.append([]); x = 0
            }
            rows[rows.count - 1].append(size); x += size.width + spacing
        }
        let height = rows.map { $0.map(\.height).max() ?? 0 }.reduce(0, +) + spacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth, x > bounds.minX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

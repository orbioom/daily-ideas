import SwiftUI
import SwiftData

struct MatchesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var decisions: [Decision]

    @AppStorage("partnerAName") private var partnerAName = "Partner A"
    @AppStorage("partnerBName") private var partnerBName = "Partner B"

    private var matches: [NameEntry] { MatchEngine.matches(in: decisions) }

    private var likedOnlyByA: [NameEntry] {
        let a = MatchEngine.likedIDs(for: .a, in: decisions)
        let b = MatchEngine.likedIDs(for: .b, in: decisions)
        let decidedB = MatchEngine.decidedIDs(for: .b, in: decisions)
        return a.subtracting(b).filter { decidedB.contains($0) == false }
            .compactMap { NameCatalog.entry(id: $0) }
            .sorted { $0.name < $1.name }
    }

    private var likedOnlyByB: [NameEntry] {
        let a = MatchEngine.likedIDs(for: .a, in: decisions)
        let b = MatchEngine.likedIDs(for: .b, in: decisions)
        let decidedA = MatchEngine.decidedIDs(for: .a, in: decisions)
        return b.subtracting(a).filter { decidedA.contains($0) == false }
            .compactMap { NameCatalog.entry(id: $0) }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            Group {
                if matches.isEmpty && likedOnlyByA.isEmpty && likedOnlyByB.isEmpty {
                    ContentUnavailableView(
                        "No Matches Yet",
                        systemImage: "heart",
                        description: Text("When both of you love the same name it lands here. Take turns on the Swipe tab — the magic is in the overlap.")
                    )
                } else {
                    List {
                        if !matches.isEmpty {
                            Section {
                                ForEach(matches) { entry in
                                    NavigationLink {
                                        NameDetailView(entry: entry)
                                    } label: {
                                        matchRow(entry)
                                    }
                                }
                            } header: {
                                Text("You Both Love")
                            } footer: {
                                Text("Newest matches first. Tap a name for its story.")
                            }
                        }
                        if !likedOnlyByA.isEmpty {
                            Section("\(partnerAName) loves — \(partnerBName) hasn't seen yet") {
                                ForEach(likedOnlyByA) { entry in
                                    pendingRow(entry)
                                }
                            }
                        }
                        if !likedOnlyByB.isEmpty {
                            Section("\(partnerBName) loves — \(partnerAName) hasn't seen yet") {
                                ForEach(likedOnlyByB) { entry in
                                    pendingRow(entry)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Matches")
        }
    }

    private func matchRow(_ entry: NameEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .foregroundStyle(MonikerTheme.roseDeep)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.title3.weight(.semibold))
                    .fontDesign(.serif)
                Text("\(entry.gender.displayName) · \(entry.origin) · “\(entry.meaning)”")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func pendingRow(_ entry: NameEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "heart")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.body.weight(.medium))
                    .fontDesign(.serif)
                Text("\(entry.gender.displayName) · \(entry.origin)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct NameDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var decisions: [Decision]
    let entry: NameEntry

    @AppStorage("partnerAName") private var partnerAName = "Partner A"
    @AppStorage("partnerBName") private var partnerBName = "Partner B"

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: entry.gender.symbol)
                            .font(.caption2)
                        Text(entry.gender.displayName.uppercased())
                            .font(.caption.weight(.semibold))
                            .tracking(1.5)
                    }
                    .foregroundStyle(MonikerTheme.genderColor(entry.gender))
                    Text(entry.name)
                        .font(.system(size: 52, weight: .semibold, design: .serif))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text("“\(entry.meaning)”")
                        .font(.title3)
                        .fontDesign(.serif)
                        .italic()
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Text("Origin: \(entry.origin)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        ForEach(entry.styles) { style in
                            StyleChip(style: style)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .monikerPanel()

                verdictPanel
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(entry.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func verdict(for partner: Partner) -> Bool? {
        decisions.first { $0.nameID == entry.id && $0.partnerRaw == partner.rawValue }?.liked
    }

    private var verdictPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Verdicts")
                .font(.headline)
            verdictRow(name: partnerAName, partner: .a)
            Divider()
            verdictRow(name: partnerBName, partner: .b)
            Text("Tap to change a verdict — matches update instantly.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .monikerPanel()
    }

    private func verdictRow(name: String, partner: Partner) -> some View {
        let liked = verdict(for: partner)
        return HStack {
            Text(name)
                .font(.body.weight(.medium))
            Spacer()
            Picker("Verdict for \(name)", selection: Binding<Int>(
                get: {
                    switch liked {
                    case .some(true): return 1
                    case .some(false): return 2
                    case nil: return 0
                    }
                },
                set: { newValue in
                    Haptics.tap()
                    for old in decisions where old.nameID == entry.id && old.partnerRaw == partner.rawValue {
                        modelContext.delete(old)
                    }
                    if newValue == 1 {
                        modelContext.insert(Decision(nameID: entry.id, partner: partner, liked: true))
                    } else if newValue == 2 {
                        modelContext.insert(Decision(nameID: entry.id, partner: partner, liked: false))
                    }
                }
            )) {
                Text("Undecided").tag(0)
                Text("Love").tag(1)
                Text("Pass").tag(2)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 240)
        }
    }
}

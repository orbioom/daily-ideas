import SwiftUI

struct ChordsView: View {
    @Environment(ProStore.self) private var pro
    @State private var section: Section = .chords
    @State private var search = ""
    @State private var difficulty: Chord.Difficulty? = nil
    @State private var showPaywall = false

    enum Section: String, CaseIterable, Identifiable {
        case chords = "Chords", progressions = "Progressions"
        var id: String { rawValue }
    }

    private let cols = [GridItem(.adaptive(minimum: 104), spacing: 14)]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    Picker("Section", selection: $section) {
                        ForEach(Section.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    if section == .chords { chordsSection } else { progressionsSection }
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    // MARK: Chords

    private var filtered: [Chord] {
        ChordLibrary.all.filter { c in
            (difficulty == nil || c.difficulty == difficulty) &&
            (search.isEmpty || c.symbol.localizedCaseInsensitiveContains(search)
             || c.quality.localizedCaseInsensitiveContains(search))
        }
    }

    @ViewBuilder private var chordsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            FilterRow(difficulty: $difficulty)

            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(Theme.inkSoft)
                TextField("Search C, Am7, barre…", text: $search)
                    .font(Theme.rounded(16, .regular))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if !search.isEmpty {
                    Button { search = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.inkFaint)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(12)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.hairline, lineWidth: 1))
            .padding(.horizontal, 16)

            if filtered.isEmpty {
                EmptyStateView(icon: "magnifyingglass",
                               title: "No chords found",
                               message: "Try a different name or clear the filter.")
            } else {
                LazyVGrid(columns: cols, spacing: 14) {
                    ForEach(filtered) { chord in
                        NavigationLink(value: chord) {
                            ChordCell(chord: chord)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 24)
        .navigationDestination(for: Chord.self) { ChordDetailView(chord: $0) }
    }

    // MARK: Progressions

    @ViewBuilder private var progressionsSection: some View {
        VStack(spacing: 14) {
            ForEach(ProgressionLibrary.all) { prog in
                if prog.pro && !pro.isPro {
                    Button { Haptics.tap(); showPaywall = true } label: {
                        ProgressionRow(prog: prog, locked: true)
                    }
                    .buttonStyle(.plain)
                } else {
                    NavigationLink(value: prog) {
                        ProgressionRow(prog: prog, locked: false)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .navigationDestination(for: Progression.self) { ProgressionDetailView(prog: $0) }
    }
}

private struct FilterRow: View {
    @Binding var difficulty: Chord.Difficulty?
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Chip(title: "All", on: difficulty == nil) { difficulty = nil }
                ForEach(Chord.Difficulty.allCases) { d in
                    Chip(title: d.rawValue, on: difficulty == d) {
                        difficulty = (difficulty == d) ? nil : d
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    struct Chip: View {
        let title: String; let on: Bool; let action: () -> Void
        var body: some View {
            Button { Haptics.tap(); action() } label: {
                Text(title)
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(on ? .white : Theme.inkSoft)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(on ? Theme.accent : Theme.surfaceAlt, in: Capsule())
            }
        }
    }
}

private struct ChordCell: View {
    let chord: Chord
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(chord.symbol)
                    .font(Theme.serif(20, .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if chord.isBarre {
                    Text("barre")
                        .font(Theme.rounded(10, .bold))
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Theme.accent.opacity(0.14), in: Capsule())
                        .accessibilityHidden(true)
                }
            }
            ChordDiagram(chord: chord, showFingers: false)
                .frame(height: 96)
            Text(chord.quality)
                .font(Theme.rounded(11, .medium))
                .foregroundStyle(Theme.inkSoft)
                .lineLimit(1)
        }
        .padding(12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.hairline, lineWidth: 1))
    }
}

private struct ProgressionRow: View {
    let prog: Progression
    let locked: Bool
    var body: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(prog.name).font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink)
                        if locked {
                            Image(systemName: "lock.fill").font(.system(size: 12)).foregroundStyle(Theme.accent)
                        }
                    }
                    Text(prog.numerals).font(Theme.serif(14, .semibold)).foregroundStyle(Theme.accent)
                    Text(prog.feel).font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: locked ? "lock.fill" : "chevron.right")
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(prog.name), \(prog.numerals)\(locked ? ", locked, requires Pro" : "")")
    }
}

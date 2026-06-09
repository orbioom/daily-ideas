import SwiftUI
import SwiftData

struct DevotionsView: View {
    @Query private var prayers: [Prayer]
    @Query private var logs: [ReadingLog]

    @State private var search = ""
    @State private var themeFilter: DevotionTheme? = nil

    private var streak: Int { VesperEngine.currentStreak(prayers, logs) }
    private var readTotal: Int { VesperEngine.devotionsReadTotal(logs) }

    private var readIDs: Set<Int> { Set(logs.map(\.devotionID)) }

    private var results: [Devotion] {
        DevotionLibrary.all.filter { d in
            if let t = themeFilter, d.theme != t { return false }
            let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !q.isEmpty {
                let hay = (d.reference + " " + d.verse + " " + d.theme.label).lowercased()
                if !hay.contains(q) { return false }
            }
            return true
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        headerStats

                        if results.isEmpty {
                            EmptyStateView(icon: "magnifyingglass",
                                           title: "No readings found",
                                           message: "Try a different word or clear the theme filter.")
                                .padding(.top, 40)
                        } else {
                            ForEach(results) { devotion in
                                NavigationLink(value: devotion) {
                                    devotionCard(devotion)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Devotions")
            .searchable(text: $search, prompt: "Search by reference or text")
            .safeAreaInset(edge: .top) { themeBar }
            .navigationDestination(for: Devotion.self) { devotion in
                DevotionDetailView(devotion: devotion)
            }
        }
    }

    private var headerStats: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(streak)", label: "Day streak", tint: Brand.magic)
            StatTile(value: "\(readTotal)", label: "Devotions read")
        }
    }

    private var themeBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                SelectChip(text: "All themes", isSelected: themeFilter == nil) {
                    Haptics.selection()
                    withAnimation(Brand.ease(0.25)) { themeFilter = nil }
                }
                ForEach(DevotionTheme.allCases) { t in
                    SelectChip(text: t.label, isSelected: themeFilter == t, systemImage: t.symbol) {
                        Haptics.selection()
                        withAnimation(Brand.ease(0.25)) { themeFilter = (themeFilter == t ? nil : t) }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }

    private func devotionCard(_ devotion: Devotion) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Eyebrow(text: devotion.reference)
                    Spacer()
                    if readIDs.contains(devotion.id) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(Brand.magic)
                            .accessibilityLabel("Read")
                    }
                    ThemeChip(theme: devotion.theme)
                }
                Text(devotion.verse)
                    .font(.body.weight(.medium))
                    .italic()
                    .foregroundStyle(Brand.text)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(devotion.reference), \(devotion.theme.label)\(readIDs.contains(devotion.id) ? ", read" : "")")
        .accessibilityValue(devotion.verse)
        .accessibilityHint("Opens the reading")
    }
}

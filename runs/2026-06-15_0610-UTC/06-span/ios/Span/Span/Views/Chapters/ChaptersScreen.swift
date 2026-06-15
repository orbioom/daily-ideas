import SwiftUI
import SwiftData

/// CRUD list of life chapters (colored eras), each showing its week-span & duration.
struct ChaptersScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query(sort: \Chapter.sortOrder) private var chapters: [Chapter]
    @Query private var profiles: [LifeProfile]

    @State private var editing: Chapter?
    @State private var showNew = false
    @State private var paywallReason: PaywallReason?

    private var profile: LifeProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            Group {
                if chapters.isEmpty {
                    EmptyStateView(symbol: "book.closed",
                                   title: "No chapters yet",
                                   message: "Mark the eras of your life — childhood, school, a city, a career. Each one colors a band of weeks on your grid.",
                                   actionTitle: "Add a chapter") {
                        attemptAdd()
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    list
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Chapters")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        attemptAdd()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add chapter")
                }
            }
            .sheet(isPresented: $showNew) {
                ChapterEditorView(chapter: nil, nextSortOrder: chapters.count, palette: palette)
            }
            .sheet(item: $editing) { ch in
                ChapterEditorView(chapter: ch, nextSortOrder: chapters.count, palette: palette)
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    private var palette: Palette { settings.palette(isPro: isPro) }

    private var list: some View {
        List {
            if !isPro {
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                        Text("Free plan: \(chapters.count) of \(Pro.freeChapterLimit) chapters used.")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .listRowBackground(Theme.surface)
                }
            }
            Section {
                ForEach(chapters) { ch in
                    Button {
                        editing = ch
                    } label: {
                        ChapterRow(chapter: ch, profile: profile)
                    }
                    .listRowBackground(Theme.surface)
                }
                .onDelete(perform: delete)
                .onMove(perform: move)
            } footer: {
                Text("Tap a chapter to edit. Swipe to delete, or use Edit to reorder. Overlapping chapters layer by most recent start.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { EditButton() }
        }
    }

    private func attemptAdd() {
        if Pro.canAddChapter(count: chapters.count, isPro: isPro) {
            showNew = true
        } else {
            paywallReason = .chapters
        }
    }

    private func delete(_ offsets: IndexSet) {
        for i in offsets where chapters.indices.contains(i) {
            context.delete(chapters[i])
        }
        try? context.save()
        Haptics.light(settings.hapticsEnabled)
    }

    private func move(_ offsets: IndexSet, _ destination: Int) {
        var ordered = chapters
        ordered.move(fromOffsets: offsets, toOffset: destination)
        for (i, ch) in ordered.enumerated() { ch.sortOrder = i }
        try? context.save()
    }
}

/// A single chapter row: swatch, title, date range, duration, week-span.
struct ChapterRow: View {
    let chapter: Chapter
    let profile: LifeProfile?

    private var color: Color { Color(hexString: chapter.colorHex, fallback: Theme.accent) }

    private var durationText: String {
        let cal = Calendar(identifier: .gregorian)
        let end = chapter.endDate ?? Date()
        let comps = cal.dateComponents([.year, .month], from: chapter.startDate, to: end)
        let y = max(comps.year ?? 0, 0)
        let m = max(comps.month ?? 0, 0)
        var parts: [String] = []
        if y > 0 { parts.append("\(y)y") }
        if m > 0 { parts.append("\(m)mo") }
        return parts.isEmpty ? "under a month" : parts.joined(separator: " ")
    }

    private var weekSpanText: String? {
        guard let profile else { return nil }
        let engine = SpanEngine(profile: profile)
        let start = max(engine.weekIndex(for: chapter.startDate), 0)
        let end = max(engine.weekIndex(for: chapter.endDate ?? Date()), start)
        let weeks = end - start + 1
        return "≈ \(Fmt.grouped(max(weeks, 0))) weeks"
    }

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(color)
                .frame(width: 10, height: 40)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(chapter.title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("\(Fmt.monthYear.string(from: chapter.startDate)) – \(chapter.endDate.map { Fmt.monthYear.string(from: $0) } ?? "now")")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                HStack(spacing: 8) {
                    Text(durationText)
                    if let weekSpanText {
                        Text("·")
                        Text(weekSpanText)
                    }
                }
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.inkFaint)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

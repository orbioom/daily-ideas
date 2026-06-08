import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]

    @AppStorage("sortNewestFirst") private var newestFirst = true

    @State private var search = ""
    @State private var showSettings = false
    @State private var editing: JournalEntry?
    @State private var showOnThisDay = false

    private let calendar = Calendar.current

    private var filtered: [JournalEntry] {
        let base: [JournalEntry]
        if search.trimmingCharacters(in: .whitespaces).isEmpty {
            base = entries
        } else {
            let q = search.lowercased()
            base = entries.filter {
                $0.title.lowercased().contains(q) ||
                $0.body.lowercased().contains(q) ||
                $0.tags.contains { $0.name.lowercased().contains(q) }
            }
        }
        return newestFirst ? base : base.reversed()
    }

    private var pinned: [JournalEntry] { filtered.filter { $0.pinned } }

    private var grouped: [(day: Date, items: [JournalEntry])] {
        let unpinned = filtered.filter { !$0.pinned }
        let dict = Dictionary(grouping: unpinned) { calendar.startOfDay(for: $0.date) }
        return dict.map { (day: $0.key, items: $0.value) }
            .sorted { newestFirst ? $0.day > $1.day : $0.day < $1.day }
    }

    private var onThisDay: [JournalEntry] {
        JournalEngine(calendar: calendar).onThisDay(entries)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                content
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        let entry = JournalEntry()
                        context.insert(entry)
                        editing = entry
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("New entry")
                }
            }
            .searchable(text: $search, prompt: "Search entries")
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(item: $editing) { entry in
                EntryEditorView(entry: entry)
            }
            .sheet(isPresented: $showOnThisDay) {
                OnThisDayView(entries: onThisDay)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if entries.isEmpty {
            ScrollView {
                promptCard
                    .padding(.horizontal)
                    .padding(.top, 8)
                EmptyStateView(
                    icon: "book.closed",
                    title: "Your journal is empty",
                    message: "Tap the pencil to write your first entry, or start from today's prompt above."
                )
            }
        } else if filtered.isEmpty {
            EmptyStateView(
                icon: "magnifyingglass",
                title: "No matches",
                message: "No entries match “\(search)”. Try a different word."
            )
        } else {
            List {
                Section {
                    promptCard
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                        .listRowBackground(Color.clear)
                    if !onThisDay.isEmpty {
                        onThisDayCard
                            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 8, trailing: 12))
                            .listRowBackground(Color.clear)
                    }
                }

                if !pinned.isEmpty {
                    Section("Pinned") {
                        ForEach(pinned) { entry in rowLink(entry) }
                    }
                }

                ForEach(grouped, id: \.day) { group in
                    Section(sectionTitle(group.day)) {
                        ForEach(group.items) { entry in rowLink(entry) }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }

    private func rowLink(_ entry: JournalEntry) -> some View {
        Button {
            editing = entry
        } label: {
            EntryRow(entry: entry)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading) {
            Button {
                entry.pinned.toggle()
                entry.modifiedAt = .now
                Haptics.selection()
            } label: {
                Label(entry.pinned ? "Unpin" : "Pin", systemImage: "pin")
            }
            .tint(Color(hex: 0x6E7BA6))
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                context.delete(entry)
                Haptics.warning()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var promptCard: some View {
        let prompt = PromptLibrary.promptOfDay()
        return Button {
            Haptics.tap()
            let entry = JournalEntry(promptText: prompt.text)
            context.insert(entry)
            editing = entry
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.accentColor)
                    Eyebrow(text: "Today's Prompt")
                    Spacer()
                }
                Text(prompt.text)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Brand.text)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Tap to write")
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }
            .glassCard()
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens a new entry with this prompt")
    }

    private var onThisDayCard: some View {
        Button {
            showOnThisDay = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("On this day")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.text)
                    Text("\(onThisDay.count) past \(onThisDay.count == 1 ? "entry" : "entries") from this date")
                        .font(.caption)
                        .foregroundStyle(Brand.text2)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Brand.text3)
            }
            .glassCard(padding: 14)
        }
        .buttonStyle(.plain)
    }

    private func sectionTitle(_ day: Date) -> String {
        Format.relativeDay(day, relativeTo: .now, calendar: calendar)
    }
}

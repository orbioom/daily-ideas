import SwiftUI
import SwiftData

struct AddEpisodeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var show: PodcastShow
    var episodeToEdit: PodcastEpisode? = nil

    @State private var title = ""
    @State private var episodeNumber = ""
    @State private var seasonNumber = ""
    @State private var durationMinutes = "30"
    @State private var publishedDate: Date = Date()
    @State private var hasDate = false
    @State private var isListened = false
    @State private var isInQueue = false
    @State private var rating = 0
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Episode") {
                    TextField("Episode title", text: $title)
                        .accessibilityLabel("Episode title")
                    HStack {
                        TextField("Episode #", text: $episodeNumber)
                            .keyboardType(.numberPad)
                            .accessibilityLabel("Episode number")
                        Divider()
                        TextField("Season #", text: $seasonNumber)
                            .keyboardType(.numberPad)
                            .accessibilityLabel("Season number")
                    }
                    HStack {
                        TextField("Duration", text: $durationMinutes)
                            .keyboardType(.numberPad)
                            .accessibilityLabel("Duration in minutes")
                        Text("min").foregroundStyle(.secondary)
                    }
                }
                Section("Published") {
                    Toggle("Set a date", isOn: $hasDate)
                    if hasDate {
                        DatePicker("Date", selection: $publishedDate, displayedComponents: .date)
                    }
                }
                Section("Status") {
                    Toggle("I've listened to this", isOn: $isListened)
                        .tint(.green)
                        .onChange(of: isListened) { _, new in
                            if new { isInQueue = false }
                        }
                    if !isListened {
                        Toggle("Add to queue", isOn: $isInQueue)
                            .tint(CastTheme.amber)
                    }
                }
                Section("Rating") {
                    HStack(spacing: 10) {
                        ForEach(1...5, id: \.self) { i in
                            Button { rating = rating == i ? 0 : i } label: {
                                Image(systemName: i <= rating ? "star.fill" : "star")
                                    .foregroundStyle(i <= rating ? .yellow : .secondary)
                            }
                        }
                        Spacer()
                    }
                }
                Section("Notes") {
                    TextEditor(text: $notes).frame(minHeight: 60)
                }
            }
            .navigationTitle("Episode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                guard let e = episodeToEdit else { return }
                title = e.title
                episodeNumber = e.episodeNumber > 0 ? "\(e.episodeNumber)" : ""
                seasonNumber = e.seasonNumber > 0 ? "\(e.seasonNumber)" : ""
                durationMinutes = "\(e.durationMinutes)"
                if let d = e.publishedDate { publishedDate = d; hasDate = true }
                isListened = e.isListened; isInQueue = e.isInQueue
                rating = e.rating; notes = e.notes
            }
        }
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        let ep = episodeToEdit ?? PodcastEpisode(title: t)
        ep.title = t
        ep.episodeNumber = Int(episodeNumber) ?? 0
        ep.seasonNumber = Int(seasonNumber) ?? 0
        ep.durationMinutes = max(1, Int(durationMinutes) ?? 30)
        ep.publishedDate = hasDate ? publishedDate : nil
        ep.isListened = isListened
        if isListened && ep.listenedDate == nil { ep.listenedDate = Date() }
        ep.isInQueue = isInQueue
        ep.rating = rating; ep.notes = notes
        if episodeToEdit == nil {
            ep.show = show
            show.episodes.append(ep)
            context.insert(ep)
        }
        dismiss()
    }
}

struct EpisodeDetailView: View {
    @Bindable var episode: PodcastEpisode
    @State private var showEdit = false

    var body: some View {
        List {
            Section("Episode Info") {
                if !episode.episodeLabel.isEmpty {
                    LabeledContent("Episode", value: episode.episodeLabel)
                }
                LabeledContent("Duration", value: episode.durationFormatted)
                if let d = episode.publishedDate {
                    LabeledContent("Published", value: d.formatted(date: .abbreviated, time: .omitted))
                }
            }
            Section("Status") {
                Toggle("Listened", isOn: $episode.isListened)
                    .tint(.green)
                    .onChange(of: episode.isListened) { _, new in
                        episode.listenedDate = new ? Date() : nil
                    }
                if !episode.isListened {
                    Toggle("In Queue", isOn: $episode.isInQueue)
                        .tint(CastTheme.amber)
                }
                if let ld = episode.listenedDate {
                    LabeledContent("Listened on", value: ld.formatted(date: .abbreviated, time: .omitted))
                }
            }
            if episode.rating > 0 || !episode.notes.isEmpty {
                Section("My Take") {
                    if episode.rating > 0 {
                        HStack {
                            Text("Rating")
                            Spacer()
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { i in
                                    Image(systemName: i <= episode.rating ? "star.fill" : "star")
                                        .font(.caption)
                                        .foregroundStyle(i <= episode.rating ? .yellow : .tertiary)
                                }
                            }
                        }
                    }
                    if !episode.notes.isEmpty {
                        Text(episode.notes).font(.body).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(episode.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) {
            AddEpisodeView(show: episode.show ?? PodcastShow(title: ""), episodeToEdit: episode)
        }
    }
}

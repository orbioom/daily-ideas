import SwiftUI
import SwiftData

struct ScriptsListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Script.updatedAt, order: .reverse) private var scripts: [Script]
    @AppStorage("didSeedSamples") private var didSeedSamples = false
    @AppStorage("defaultWPM") private var defaultWPM = 150.0
    @State private var searchText = ""
    @State private var editingScript: Script?
    @State private var creatingNew = false
    @State private var playingScript: Script?

    private var filtered: [Script] {
        let base = scripts.sorted { ($0.isFavorite ? 1 : 0, $0.updatedAt.timeIntervalSince1970) > ($1.isFavorite ? 1 : 0, $1.updatedAt.timeIntervalSince1970) }
        guard !searchText.isEmpty else { return base }
        return base.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.body.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if scripts.isEmpty {
                    EmptyStateView(
                        icon: "doc.text",
                        title: "No scripts yet",
                        message: "Write or paste what you want to read — a video intro, a toast, a lecture — and Lectern will roll it for you.",
                        actionTitle: "New script"
                    ) { creatingNew = true }
                } else if filtered.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No matches",
                        message: "No script title or body contains “\(searchText)”."
                    )
                } else {
                    List {
                        ForEach(filtered) { script in
                            ScriptRowView(script: script, wpm: defaultWPM) {
                                playingScript = script
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { editingScript = script }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    script.isFavorite.toggle()
                                    Haptics.tap()
                                } label: {
                                    Label(script.isFavorite ? "Unpin" : "Pin",
                                          systemImage: script.isFavorite ? "pin.slash" : "pin")
                                }
                                .tint(Theme.accent)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    context.delete(script)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    duplicate(script)
                                } label: {
                                    Label("Duplicate", systemImage: "plus.square.on.square")
                                }
                                .tint(.indigo)
                            }
                            .listRowBackground(Theme.bgElevated)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.bgPrimary)
            .navigationTitle("Lectern")
            .searchable(text: $searchText, prompt: "Search scripts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        creatingNew = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("New script")
                }
            }
            .sheet(item: $editingScript) { script in
                ScriptEditorView(script: script)
            }
            .sheet(isPresented: $creatingNew) {
                ScriptEditorView(script: nil)
            }
            .fullScreenCover(item: $playingScript) { script in
                PrompterView(script: script)
            }
            .onAppear(perform: seedIfNeeded)
        }
    }

    private func duplicate(_ script: Script) {
        let copy = Script(title: script.title + " copy", body: script.body)
        context.insert(copy)
        Haptics.tap()
    }

    private func seedIfNeeded() {
        guard !didSeedSamples, scripts.isEmpty else { return }
        didSeedSamples = true
        for sample in SeedData.samples {
            context.insert(sample)
        }
    }
}

struct ScriptRowView: View {
    let script: Script
    let wpm: Double
    let onPlay: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    if script.isFavorite {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                    }
                    Text(script.title)
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                }
                Text(script.body)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
                Text("\(script.wordCount) words · ~\(TextStats.formatDuration(TextStats.estimatedDuration(words: script.wordCount, wordsPerMinute: wpm))) at \(Int(wpm)) wpm")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary.opacity(0.8))
            }
            Spacer(minLength: 8)
            Button(action: {
                Haptics.tap()
                onPlay()
            }) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Theme.accent)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Play \(script.title) in the prompter")
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

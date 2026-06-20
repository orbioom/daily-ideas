import SwiftUI
import SwiftData

struct StoryDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var story: FableStory
    @State private var showEdit = false
    @State private var showReader = false
    @State private var showAddChar = false
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            storyHeader

            Picker("Section", selection: $selectedTab) {
                Text("Story").tag(0)
                Text("Characters").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .accessibilityLabel("Story section")

            switch selectedTab {
            case 0: storyContent
            default: charactersList
            }
        }
        .navigationTitle(story.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: { story.isFavorite.toggle(); try? context.save() }) {
                        Image(systemName: story.isFavorite ? "star.fill" : "star")
                            .foregroundColor(story.isFavorite ? .yellow : .primary)
                    }
                    .accessibilityLabel(story.isFavorite ? "Remove from favorites" : "Add to favorites")
                    Button(action: { showEdit = true }) {
                        Image(systemName: "pencil")
                    }
                    .accessibilityLabel("Edit story")
                }
            }
        }
        .sheet(isPresented: $showEdit) { AddEditStoryView(story: story) }
        .sheet(isPresented: $showReader) { StoryReaderView(story: story) }
        .sheet(isPresented: $showAddChar) { AddCharacterView(story: story) }
    }

    private var storyHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Label(story.genre.rawValue, systemImage: story.genre.icon)
                    .font(.caption.weight(.medium))
                    .foregroundColor(FableTheme.genreColor(story.genre))
                Spacer()
                Text(story.ageGroup.rawValue)
                    .font(.caption)
                    .foregroundColor(FableTheme.secondaryLabel)
            }
            .padding(.horizontal)

            if !story.moralLesson.isEmpty {
                HStack {
                    Image(systemName: "lightbulb.fill").foregroundColor(FableTheme.gold).font(.caption)
                    Text(story.moralLesson)
                        .font(.caption)
                        .foregroundColor(FableTheme.secondaryLabel)
                    Spacer()
                }
                .padding(.horizontal)
            }

            HStack(spacing: 12) {
                if story.readCount > 0 {
                    Label("Read \(story.readCount)x", systemImage: "book.fill")
                        .font(.caption2)
                        .foregroundColor(FableTheme.secondaryLabel)
                }
                Label(story.estimatedReadTime, systemImage: "clock")
                    .font(.caption2)
                    .foregroundColor(FableTheme.secondaryLabel)
                Spacer()
                Button(action: {
                    story.readCount += 1
                    story.lastReadAt = Date()
                    try? context.save()
                    showReader = true
                }) {
                    Label("Read Aloud", systemImage: "speaker.wave.2.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Capsule().fill(FableTheme.accent))
                }
                .accessibilityLabel("Read story aloud")
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
        .background(FableTheme.secondary)
    }

    private var storyContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if story.sortedPages.isEmpty {
                    if story.content.isEmpty {
                        VStack(spacing: 12) {
                            Text("No story content yet.").foregroundColor(FableTheme.secondaryLabel)
                            Button("Edit Story") { showEdit = true }
                                .accessibilityLabel("Edit story content")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        Text(story.content)
                            .font(.body)
                            .foregroundColor(FableTheme.label)
                            .padding()
                    }
                } else {
                    ForEach(story.sortedPages) { page in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Page \(page.pageNumber)")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(FableTheme.accent)
                            Text(page.text)
                                .font(.body)
                                .foregroundColor(FableTheme.label)
                            if !page.illustrationNote.isEmpty {
                                HStack {
                                    Image(systemName: "paintbrush.fill").font(.caption2)
                                    Text(page.illustrationNote).font(.caption)
                                }
                                .foregroundColor(FableTheme.purple)
                            }
                            Divider().padding(.top, 8)
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                    }
                }
            }
        }
    }

    private var charactersList: some View {
        List {
            if story.characters.isEmpty {
                Section {
                    VStack(spacing: 8) {
                        Text("No characters yet").foregroundColor(FableTheme.secondaryLabel)
                        Button("Add Character") { showAddChar = true }
                            .accessibilityLabel("Add a character")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
            } else {
                ForEach(story.characters) { char in
                    CharacterRowView(character: char)
                }
                .onDelete { idx in
                    let sorted = story.characters
                    for i in idx { context.delete(sorted[i]) }
                    try? context.save()
                }
            }
            Section {
                Button(action: { showAddChar = true }) {
                    Label("Add Character", systemImage: "plus.circle")
                        .foregroundColor(FableTheme.accent)
                }
                .accessibilityLabel("Add character")
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct CharacterRowView: View {
    let character: StoryCharacter

    var body: some View {
        HStack(spacing: 12) {
            Text(character.emoji)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(Circle().fill(FableTheme.secondary))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(character.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(FableTheme.label)
                Text(character.role.rawValue)
                    .font(.caption)
                    .foregroundColor(FableTheme.accent)
                if !character.traits.isEmpty {
                    Text(character.traits)
                        .font(.caption)
                        .foregroundColor(FableTheme.secondaryLabel)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(character.name), \(character.role.rawValue)")
    }
}

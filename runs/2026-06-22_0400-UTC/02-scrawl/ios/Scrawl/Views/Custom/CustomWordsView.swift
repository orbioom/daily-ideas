import SwiftUI
import SwiftData

struct CustomWordsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomWordList.createdAt, order: .reverse) private var customLists: [CustomWordList]

    @State private var showingCreateSheet = false
    @State private var editingList: CustomWordList? = nil

    var body: some View {
        NavigationStack {
            Group {
                if customLists.isEmpty {
                    emptyState
                } else {
                    listContent
                }
            }
            .background(ScrawlTheme.background.ignoresSafeArea())
            .navigationTitle("Custom Words")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(ScrawlTheme.skyBlue)
                    }
                    .accessibilityLabel("Create new word list")
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                EditCustomListView(list: nil)
            }
            .sheet(item: $editingList) { list in
                EditCustomListView(list: list)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Text("✍️")
                .font(.system(size: 64))

            VStack(spacing: 8) {
                Text("No custom lists yet")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(ScrawlTheme.primaryText)

                Text("Create your own word lists with inside jokes, your city, your family — anything goes!")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(ScrawlTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                showingCreateSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Create Word List")
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(ScrawlTheme.skyBlue)
                .cornerRadius(14)
                .shadow(color: ScrawlTheme.skyBlue.opacity(0.35), radius: 8, x: 0, y: 4)
            }
            .accessibilityLabel("Create your first word list")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var listContent: some View {
        List {
            ForEach(customLists) { list in
                CustomListRow(list: list) {
                    editingList = list
                }
                .listRowBackground(ScrawlTheme.background)
                .listRowSeparator(.hidden)
                .padding(.vertical, 4)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    modelContext.delete(customLists[index])
                }
                try? modelContext.save()
            }
        }
        .listStyle(.plain)
    }
}

struct CustomListRow: View {
    let list: CustomWordList
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(ScrawlTheme.coral.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Text("✍️")
                        .font(.system(size: 24))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(list.name)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(ScrawlTheme.primaryText)

                        if !list.isValid {
                            Text("Need \(5 - list.wordCount) more")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(ScrawlTheme.warningOrange)
                                .cornerRadius(6)
                        }
                    }

                    Text(list.wordCount == 0 ? "No words yet" : list.displayWords)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(ScrawlTheme.secondaryText)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(list.wordCount)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(list.isValid ? ScrawlTheme.skyBlue : ScrawlTheme.warningOrange)
                    Text("words")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(ScrawlTheme.secondaryText)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ScrawlTheme.secondaryText)
            }
            .padding(14)
            .scrawlCard()
        }
        .accessibilityLabel("\(list.name), \(list.wordCount) words")
    }
}

struct EditCustomListView: View {
    let list: CustomWordList?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var words: [String] = []
    @State private var newWordText: String = ""
    @FocusState private var isNewWordFocused: Bool

    var isEditing: Bool { list != nil }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Label("List Name", systemImage: "tag.fill")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(ScrawlTheme.secondaryText)

                        TextField("e.g. Family Night, Office Party...", text: $name)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .padding(14)
                            .background(ScrawlTheme.cardBackground)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                            .accessibilityLabel("Word list name")
                    }

                    // Add word
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Words", systemImage: "text.word.spacing")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(ScrawlTheme.secondaryText)

                            Spacer()

                            Text("\(words.count) words\(words.count < 5 ? " (need \(5 - words.count) more)" : "")")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(words.count < 5 ? ScrawlTheme.warningOrange : ScrawlTheme.successGreen)
                        }

                        HStack(spacing: 10) {
                            TextField("Add a word...", text: $newWordText)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .padding(14)
                                .background(ScrawlTheme.cardBackground)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                                .focused($isNewWordFocused)
                                .submitLabel(.done)
                                .onSubmit { addWord() }
                                .accessibilityLabel("New word to add")

                            Button(action: addWord) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(
                                        newWordText.trimmingCharacters(in: .whitespaces).isEmpty
                                            ? ScrawlTheme.warmGray
                                            : ScrawlTheme.skyBlue
                                    )
                            }
                            .disabled(newWordText.trimmingCharacters(in: .whitespaces).isEmpty)
                            .accessibilityLabel("Add word")
                        }
                    }

                    // Words list
                    if !words.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(words.indices, id: \.self) { index in
                                HStack {
                                    Text(words[index])
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundStyle(ScrawlTheme.primaryText)

                                    Spacer()

                                    Button {
                                        words.remove(at: index)
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 15))
                                            .foregroundStyle(ScrawlTheme.coral)
                                    }
                                    .accessibilityLabel("Remove \(words[index])")
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)

                                if index < words.count - 1 {
                                    Divider()
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .background(ScrawlTheme.cardBackground)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(ScrawlTheme.background.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit List" : "New Word List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(ScrawlTheme.coral)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveList() }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(canSave ? ScrawlTheme.skyBlue : ScrawlTheme.warmGray)
                        .disabled(!canSave)
                        .accessibilityLabel("Save word list")
                }
            }
        }
        .onAppear {
            if let list {
                name = list.name
                words = list.words
            }
        }
    }

    private func addWord() {
        let trimmed = newWordText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !words.contains(trimmed) else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            words.append(trimmed)
        }
        newWordText = ""
    }

    private func saveList() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if let existing = list {
            existing.name = trimmedName
            existing.words = words
        } else {
            let newList = CustomWordList(name: trimmedName, words: words)
            modelContext.insert(newList)
        }
        try? modelContext.save()
        dismiss()
    }
}

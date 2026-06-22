import SwiftUI
import SwiftData

struct CustomPackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var pack: CustomPack?

    @State private var packName = ""
    @State private var wordInput = ""
    @State private var words: [String] = []
    @State private var bulkInput = ""
    @State private var showBulkEntry = false
    @State private var errorMessage = ""

    var isEditing: Bool { pack != nil }
    var canSave: Bool { !packName.isEmpty && words.count >= 24 }

    var body: some View {
        NavigationStack {
            ZStack {
                BingoTheme.navy.ignoresSafeArea()

                Form {
                    Section("Pack Name") {
                        TextField("e.g. Family Reunion 2026", text: $packName)
                            .foregroundColor(.white)
                            .listRowBackground(BingoTheme.lightNavy)
                    }

                    Section("Add Words") {
                        HStack {
                            TextField("Add a word or phrase", text: $wordInput)
                                .foregroundColor(.white)
                                .onSubmit { addWord() }
                            Button(action: addWord) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(BingoTheme.gold)
                            }
                        }
                        .listRowBackground(BingoTheme.lightNavy)

                        Button(action: { showBulkEntry.toggle() }) {
                            Label("Paste comma-separated list", systemImage: "text.badge.plus")
                                .foregroundColor(BingoTheme.gold)
                        }
                        .listRowBackground(BingoTheme.lightNavy)

                        if showBulkEntry {
                            VStack(alignment: .leading, spacing: 8) {
                                TextEditor(text: $bulkInput)
                                    .frame(height: 80)
                                    .foregroundColor(.white)
                                    .scrollContentBackground(.hidden)
                                    .background(BingoTheme.navy.opacity(0.5))
                                    .cornerRadius(8)

                                Button("Add All") {
                                    addBulkWords()
                                    showBulkEntry = false
                                }
                                .font(.subheadline.bold())
                                .foregroundColor(BingoTheme.navy)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(BingoTheme.gold)
                                .cornerRadius(8)
                            }
                            .listRowBackground(BingoTheme.lightNavy)
                        }
                    }

                    if !errorMessage.isEmpty {
                        Section {
                            Text(errorMessage)
                                .foregroundColor(BingoTheme.red)
                                .font(.subheadline)
                                .listRowBackground(BingoTheme.lightNavy)
                        }
                    }

                    Section(
                        header: HStack {
                            Text("WORDS (\(words.count)/24 minimum)")
                                .foregroundColor(words.count >= 24 ? BingoTheme.gold : BingoTheme.red)
                            Spacer()
                            if !words.isEmpty {
                                Button("Clear All") { words = [] }
                                    .font(.caption)
                                    .foregroundColor(BingoTheme.red)
                            }
                        }
                    ) {
                        if words.isEmpty {
                            Text("No words added yet. You need at least 24 words.")
                                .foregroundColor(.white.opacity(0.5))
                                .font(.subheadline)
                                .listRowBackground(BingoTheme.lightNavy)
                        } else {
                            ForEach(words.indices, id: \.self) { i in
                                HStack {
                                    Text("\(i + 1).")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.4))
                                        .frame(width: 24)
                                    Text(words[i])
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .listRowBackground(BingoTheme.lightNavy)
                            }
                            .onDelete { indices in
                                words.remove(atOffsets: indices)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isEditing ? "Edit Pack" : "New Pack")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(BingoTheme.navy, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(BingoTheme.gold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { savePack() }
                        .foregroundColor(canSave ? BingoTheme.gold : .gray)
                        .disabled(!canSave)
                }
            }
            .onAppear {
                if let existing = pack {
                    packName = existing.name
                    words = existing.words
                }
            }
        }
    }

    private func addWord() {
        let trimmed = wordInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !words.contains(trimmed) else {
            errorMessage = "'\(trimmed)' is already in the list."
            return
        }
        words.append(trimmed)
        wordInput = ""
        errorMessage = ""
    }

    private func addBulkWords() {
        let newWords = bulkInput
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !words.contains($0) }
        words.append(contentsOf: newWords)
        bulkInput = ""
    }

    private func savePack() {
        guard canSave else { return }

        if let existing = pack {
            existing.name = packName
            existing.words = words
        } else {
            let newPack = CustomPack(name: packName, words: words)
            modelContext.insert(newPack)
        }
        try? modelContext.save()
        dismiss()
    }
}

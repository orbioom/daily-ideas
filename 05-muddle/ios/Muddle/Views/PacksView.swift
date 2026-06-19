import SwiftUI
import SwiftData

struct PacksView: View {
    @Query private var progresses: [PackProgress]
    @Environment(\.modelContext) private var ctx
    @State private var selectedCategory: WordCategory?
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var puzzleEntry: WordEntry?
    @State private var showPuzzle = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    categoryGrid
                    if let cat = selectedCategory {
                        difficultyPicker
                        wordList(for: cat, difficulty: selectedDifficulty)
                    }
                }
                .padding()
            }
            .navigationTitle("Word Packs")
            .sheet(item: $puzzleEntry) { entry in
                PackPuzzleView(entry: entry) { solved in
                    markCompleted(entry: entry)
                }
            }
        }
    }

    private var categoryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(WordCategory.allCases, id: \.self) { cat in
                Button { withAnimation { selectedCategory = (selectedCategory == cat) ? nil : cat } } label: {
                    HStack {
                        Text(cat.emoji).font(.title2)
                        Text(cat.label).fontWeight(.semibold)
                        Spacer()
                        if selectedCategory == cat {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.purple)
                        }
                    }
                    .padding()
                    .background(selectedCategory == cat ? Color.purple.opacity(0.15) : Color(.systemGray6), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var difficultyPicker: some View {
        Picker("Difficulty", selection: $selectedDifficulty) {
            ForEach(Difficulty.allCases, id: \.self) { d in Text(d.label).tag(d) }
        }
        .pickerStyle(.segmented)
    }

    private func wordList(for cat: WordCategory, difficulty: Difficulty) -> some View {
        let words = WordDatabase.words(for: cat, difficulty: difficulty)
        let completed = completedWords(cat: cat.rawValue, diff: difficulty.rawValue)
        return VStack(spacing: 8) {
            if words.isEmpty {
                Text("No words in this pack")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(words) { entry in
                    Button { puzzleEntry = entry } label: {
                        HStack {
                            Image(systemName: completed.contains(entry.word) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(completed.contains(entry.word) ? .green : .secondary)
                            Text(completed.contains(entry.word) ? entry.word : "?????")
                                .fontWeight(.medium)
                            Spacer()
                            Text(entry.hint)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .padding()
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func completedWords(cat: String, diff: String) -> Set<String> {
        let key = "\(cat)_\(diff)"
        return Set(progresses.first(where: { $0.key == key })?.completedWords ?? [])
    }

    private func markCompleted(entry: WordEntry) {
        let key = "\(entry.category.rawValue)_\(entry.difficulty.rawValue)"
        if let p = progresses.first(where: { $0.key == key }) {
            if !p.completedWords.contains(entry.word) { p.completedWords.append(entry.word) }
            p.lastPlayed = Date()
        } else {
            let p = PackProgress(category: entry.category.rawValue, difficulty: entry.difficulty.rawValue)
            p.completedWords = [entry.word]
            ctx.insert(p)
        }
    }
}

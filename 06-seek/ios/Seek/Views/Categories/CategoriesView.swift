import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Query private var settingsList: [SeekSettings]
    @Environment(\.modelContext) private var modelContext
    @State private var selectedCategory: WordCategory? = nil
    @State private var difficulty: PuzzleDifficulty = .medium

    private var settings: SeekSettings {
        settingsList.first ?? SeekSettings()
    }

    var body: some View {
        ZStack {
            SeekTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    difficultyPicker
                    categoryGrid
                }
                .padding(16)
            }
        }
        .navigationTitle("Seek")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(SeekTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            difficulty = PuzzleDifficulty(rawValue: settings.preferredDifficulty) ?? .medium
        }
        .fullScreenCover(item: $selectedCategory) { cat in
            PuzzleView(category: cat, difficulty: difficulty)
        }
    }

    var difficultyPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Difficulty")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SeekTheme.textSecondary)
            HStack(spacing: 10) {
                ForEach(PuzzleDifficulty.allCases, id: \.self) { d in
                    Button {
                        withAnimation { difficulty = d }
                    } label: {
                        VStack(spacing: 4) {
                            Text(d.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                            Text("\(d.gridSize)×\(d.gridSize)")
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(difficulty == d ? .black : SeekTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(difficulty == d ? SeekTheme.accent : SeekTheme.surface, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .padding(14)
        .background(SeekTheme.surface, in: RoundedRectangle(cornerRadius: 14))
    }

    var categoryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(WordCategory.all) { cat in
                CategoryCard(category: cat) {
                    selectedCategory = cat
                }
            }
        }
    }
}

struct CategoryCard: View {
    let category: WordCategory
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(SeekTheme.accent)
                Text(category.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SeekTheme.textPrimary)
                Text("\(category.words.count) words")
                    .font(.system(size: 12))
                    .foregroundStyle(SeekTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(SeekTheme.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(SeekTheme.accent.opacity(0.15), lineWidth: 1)
            )
        }
        .accessibilityLabel("\(category.name) category, \(category.words.count) words")
    }
}

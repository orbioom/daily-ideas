import SwiftUI
import SwiftData

struct PuzzleView: View {
    @State private var puzzle: SlidePuzzle = SlidePuzzle.make(size: 4)
    @State private var selectedSize: Int = 4
    @State private var selectedTheme: SlideArtTheme = .classic
    @State private var isSolved: Bool = false
    @State private var showSizeSheet: Bool = false
    @State private var showThemeSheet: Bool = false
    @Environment(\.modelContext) private var ctx
    @Query private var prefs: [SlidePrefs]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var currentPrefs: SlidePrefs? { prefs.first }

    var body: some View {
        ZStack {
            SlideTheme.background.ignoresSafeArea()
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(selectedSize)×\(selectedSize)")
                            .font(.caption)
                            .foregroundStyle(SlideTheme.textSecondary)
                        Text("Moves: \(puzzle.moves)")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Button(action: { showThemeSheet = true }) {
                        Image(systemName: "paintpalette")
                            .foregroundStyle(SlideTheme.accent)
                    }
                    .padding(.trailing, 8)
                    Button(action: { showSizeSheet = true }) {
                        Image(systemName: "aspectratio")
                            .foregroundStyle(SlideTheme.accent)
                    }
                }
                .padding(.horizontal)

                TileGridView(
                    puzzle: $puzzle,
                    theme: selectedTheme,
                    isSolved: $isSolved,
                    reduceMotion: reduceMotion
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()

                // New Game button
                Button(action: { startNewGame() }) {
                    Text("New Game")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(SlideTheme.tileBg, in: .capsule)
                }
                .padding(.bottom)
            }
        }
        .navigationTitle("Slide")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isSolved) {
            SolvedView(
                moves: puzzle.moves,
                seconds: puzzle.elapsedSeconds,
                size: selectedSize,
                theme: selectedTheme.rawValue,
                onNewGame: { isSolved = false; startNewGame() }
            )
        }
        .sheet(isPresented: $showSizeSheet) {
            SizePicker(selectedSize: $selectedSize, onSelect: { startNewGame() })
                .presentationDetents([.height(250)])
        }
        .sheet(isPresented: $showThemeSheet) {
            ThemePicker(selectedTheme: $selectedTheme, isPro: currentPrefs?.isPro ?? false)
                .presentationDetents([.height(350)])
        }
        .onChange(of: isSolved) { _, newVal in
            if newVal { saveRecord() }
        }
    }

    private func startNewGame() {
        puzzle = SlidePuzzle.make(size: selectedSize)
        isSolved = false
    }

    private func saveRecord() {
        let record = SlideRecord(
            size: selectedSize,
            moves: puzzle.moves,
            seconds: puzzle.elapsedSeconds,
            theme: selectedTheme.rawValue
        )
        ctx.insert(record)
        try? ctx.save()
    }
}

struct SizePicker: View {
    @Binding var selectedSize: Int
    let onSelect: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Grid Size").font(.headline).padding(.top)
            ForEach([3, 4, 5], id: \.self) { size in
                Button(action: { selectedSize = size; onSelect(); dismiss() }) {
                    HStack {
                        Text("\(size)×\(size) — \(size * size - 1) tiles")
                            .foregroundStyle(.primary)
                        Spacer()
                        if selectedSize == size {
                            Image(systemName: "checkmark")
                                .foregroundStyle(SlideTheme.accent)
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: .rect(cornerRadius: 12))
                }
            }
            Spacer()
        }
        .padding()
    }
}

struct ThemePicker: View {
    @Binding var selectedTheme: SlideArtTheme
    let isPro: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            Text("Theme").font(.headline).padding(.top)
            ForEach(SlideArtTheme.allCases) { theme in
                Button(action: {
                    if !theme.isPro || isPro {
                        selectedTheme = theme
                        dismiss()
                    }
                }) {
                    HStack {
                        Circle()
                            .fill(theme.accent)
                            .frame(width: 24, height: 24)
                        Text(theme.name).foregroundStyle(.primary)
                        if theme.isPro && !isPro {
                            Text("PRO").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if selectedTheme == theme {
                            Image(systemName: "checkmark")
                                .foregroundStyle(SlideTheme.accent)
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: .rect(cornerRadius: 12))
                    .opacity((theme.isPro && !isPro) ? 0.5 : 1.0)
                }
                .disabled(theme.isPro && !isPro)
            }
            Spacer()
        }
        .padding()
    }
}

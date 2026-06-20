import SwiftUI
import SwiftData

struct PuzzleSelectView: View {
    @AppStorage("defaultDifficulty") private var defaultDifficulty = PuzzleDifficulty.beginner.rawValue
    @AppStorage("isPro") private var isPro = false
    @Environment(\.modelContext) private var ctx
    @Query(sort: \PuzzleSave.startDate, order: .reverse) private var saves: [PuzzleSave]

    @State private var selectedStyle: PuzzleArtStyle = .mountainSunset
    @State private var selectedDifficulty: PuzzleDifficulty = .beginner
    @State private var activeGame: PuzzleEngine?
    @State private var showProAlert = false

    private var latestSave: PuzzleSave? {
        saves.first { !$0.decodeOrder().isEmpty }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PieceTheme.darkBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Resume banner
                        if let save = latestSave, !allPlaced(save: save) {
                            resumeBanner(save: save)
                        }

                        // Puzzle picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose Artwork")
                                .font(.headline)
                                .foregroundStyle(PieceTheme.subtleText)
                                .padding(.horizontal, 20)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(PuzzleArtStyle.allCases) { style in
                                        artworkCard(style)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }

                        // Difficulty picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Difficulty")
                                .font(.headline)
                                .foregroundStyle(PieceTheme.subtleText)
                                .padding(.horizontal, 20)

                            HStack(spacing: 10) {
                                ForEach(PuzzleDifficulty.allCases) { d in
                                    difficultyButton(d)
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Start button
                        NavigationLink(value: "play") {
                            Text("Start Puzzle  •  \(selectedDifficulty.pieceCount) pieces")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(PieceTheme.amber)
                                .foregroundStyle(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 20)
                        .simultaneousGesture(TapGesture().onEnded {
                            guard selectedStyle.isPro && !isPro else { return }
                            showProAlert = true
                        })
                        .disabled(selectedStyle.isPro && !isPro)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
                .navigationDestination(for: String.self) { _ in
                    PuzzlePlayView(style: selectedStyle, difficulty: selectedDifficulty)
                }
                .navigationTitle("Piece")
                .navigationBarTitleDisplayMode(.large)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .alert("Pro Feature", isPresented: $showProAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Aurora and Floral Mandala puzzles are included in the Pro unlock.")
                }
            }
        }
        .onAppear {
            if let saved = PuzzleDifficulty(rawValue: defaultDifficulty) {
                selectedDifficulty = saved
            }
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func artworkCard(_ style: PuzzleArtStyle) -> some View {
        let isSelected = selectedStyle == style
        let locked = style.isPro && !isPro

        Button {
            guard !locked else { showProAlert = true; return }
            selectedStyle = style
        } label: {
            VStack(spacing: 8) {
                PuzzleArtworkView(style: style)
                    .frame(width: 110, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(alignment: .topTrailing) {
                        if locked {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .padding(4)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .padding(6)
                        }
                    }
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(PieceTheme.amber, lineWidth: 3)
                        }
                    }

                Text(style.title)
                    .font(.caption)
                    .foregroundStyle(isSelected ? PieceTheme.amber : PieceTheme.subtleText)
                    .lineLimit(1)
            }
            .frame(width: 110)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(style.title)\(locked ? ", locked" : "")\(isSelected ? ", selected" : "")")
    }

    @ViewBuilder
    private func difficultyButton(_ d: PuzzleDifficulty) -> some View {
        let isSelected = selectedDifficulty == d
        Button {
            selectedDifficulty = d
        } label: {
            VStack(spacing: 4) {
                Text(d.emoji)
                    .font(.title2)
                Text(d.label)
                    .font(.caption.bold())
                Text("\(d.pieceCount) pcs")
                    .font(.caption2)
                    .foregroundStyle(PieceTheme.subtleText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? PieceTheme.difficultyColor(d).opacity(0.25) : PieceTheme.cardBg)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(PieceTheme.difficultyColor(d), lineWidth: 2)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(isSelected ? PieceTheme.difficultyColor(d) : .white)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(d.label) difficulty, \(d.pieceCount) pieces\(isSelected ? ", selected" : "")")
    }

    @ViewBuilder
    private func resumeBanner(save: PuzzleSave) -> some View {
        let style = PuzzleArtStyle(rawValue: save.puzzleStyleId) ?? .mountainSunset
        let diff   = PuzzleDifficulty(rawValue: save.difficultyId) ?? .beginner
        let placed = save.decodePlaced().count
        let total  = diff.pieceCount

        HStack(spacing: 12) {
            PuzzleArtworkView(style: style)
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text("Resume \(style.title)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text("\(placed)/\(total) pieces placed")
                    .font(.caption)
                    .foregroundStyle(PieceTheme.subtleText)
            }
            Spacer()
            Image(systemName: "arrow.right.circle.fill")
                .font(.title2)
                .foregroundStyle(PieceTheme.amber)
        }
        .padding(14)
        .background(PieceTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedStyle = style
            selectedDifficulty = diff
        }
        .accessibilityLabel("Resume \(style.title) puzzle, \(placed) of \(total) pieces placed")
    }

    private func allPlaced(save: PuzzleSave) -> Bool {
        let diff = PuzzleDifficulty(rawValue: save.difficultyId) ?? .beginner
        return save.decodePlaced().count >= diff.pieceCount
    }
}

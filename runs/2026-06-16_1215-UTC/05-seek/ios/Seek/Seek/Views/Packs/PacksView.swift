import SwiftUI
import SwiftData

/// Home screen: themed pack cards with solved progress and a difficulty selector.
struct PacksView: View {
    @EnvironmentObject private var pro: ProStore
    @Environment(\.modelContext) private var context
    @Query private var allProgress: [PuzzleProgress]

    @AppStorage("defaultDifficulty") private var defaultDifficultyRaw = Difficulty.easy.rawValue
    @State private var difficulty: Difficulty = .easy
    @State private var showPaywall = false

    private var packs: [WordPack] { WordPackLibrary.all }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    difficultyPicker
                        .padding(.horizontal, 16)

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                        spacing: 14
                    ) {
                        ForEach(packs) { pack in
                            packCard(pack)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .padding(.top, 8)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Seek")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !pro.isPro {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("Pro", systemImage: "crown.fill")
                                .font(Theme.rounded(14, .semibold))
                        }
                        .tint(Theme.accent)
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .onAppear {
                difficulty = Difficulty(rawValue: defaultDifficultyRaw) ?? .easy
            }
        }
    }

    private var difficultyPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Difficulty")
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(Theme.inkSoft)
            Picker("Difficulty", selection: $difficulty) {
                ForEach(Difficulty.allCases) { diff in
                    Text(diff.rawValue).tag(diff)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func packCard(_ pack: WordPack) -> some View {
        let locked = pack.isPro && !pro.isPro
        let solved = solvedCount(for: pack)
        let total = totalCount

        return NavigationLink {
            if locked {
                PackLockedView(pack: pack)
            } else {
                PuzzleListView(pack: pack, difficulty: difficulty)
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(pack.color.opacity(0.18))
                            .frame(width: 44, height: 44)
                        Image(systemName: pack.symbol)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(pack.color)
                    }
                    Spacer()
                    if locked {
                        LockBadge()
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(pack.name)
                        .font(Theme.rounded(17, .semibold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Text("\(pack.words.count) words")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }

                ProgressView(value: total == 0 ? 0 : Double(solved) / Double(total))
                    .tint(pack.color)
                Text("\(solved)/\(total) solved")
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
            .opacity(locked ? 0.92 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(pack.name)
        .accessibilityValue(locked ? "Locked. Requires Seek Pro." : "\(solved) of \(total) solved at \(difficulty.rawValue)")
        .accessibilityHint("Opens the puzzle list")
    }

    /// Total puzzles available per pack at the selected difficulty.
    private var totalCount: Int {
        pro.isPro ? FreeTier.totalPuzzlesPerPackPerDifficulty : FreeTier.totalPuzzlesPerPackPerDifficulty
    }

    private func solvedCount(for pack: WordPack) -> Int {
        let prefix = "\(pack.id)|"
        let suffix = "|\(difficulty.rawValue)"
        return allProgress.filter {
            $0.isComplete && $0.puzzleKey.hasPrefix(prefix) && $0.puzzleKey.hasSuffix(suffix)
        }.count
    }
}

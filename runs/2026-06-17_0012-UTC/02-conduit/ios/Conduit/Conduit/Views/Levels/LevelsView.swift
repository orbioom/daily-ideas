import SwiftUI
import SwiftData

/// Pack browser: a section per pack with a grid of level tiles showing solved,
/// perfect, or locked (Pro) status, plus per-pack progress.
struct LevelsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @AppStorage("isPro") private var isPro: Bool = false
    @Query private var progress: [PuzzleProgress]

    @State private var showPaywall = false

    private let columns = [GridItem(.adaptive(minimum: 64, maximum: 84), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 22) {
                    ForEach(PackID.allCases) { pack in
                        packSection(pack)
                    }
                }
                .padding(16)
            }
            .background(ConduitTheme.appBackground(scheme).ignoresSafeArea())
            .navigationTitle("Levels")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private func packSection(_ pack: PackID) -> some View {
        let puzzles = PuzzleBank.puzzles(in: pack)
        let locked = pack.requiresPro && !isPro
        let solvedInPack = puzzles.filter { isSolved($0.id) }.count

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: pack.symbol)
                    .foregroundStyle(ConduitTheme.accent)
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(pack.title)
                            .font(.headline)
                            .foregroundStyle(ConduitTheme.primaryText(scheme))
                        if locked {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundStyle(ConduitTheme.secondaryText(scheme))
                        }
                    }
                    Text(pack.subtitle)
                        .font(.caption)
                        .foregroundStyle(ConduitTheme.secondaryText(scheme))
                }
                Spacer()
                Text("\(solvedInPack)/\(puzzles.count)")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(ConduitTheme.secondaryText(scheme))
            }

            if locked {
                lockedBanner
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(puzzles) { puzzle in
                    tile(for: puzzle, locked: locked)
                }
            }
        }
    }

    private var lockedBanner: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "crown.fill").foregroundStyle(.white)
                Text("Unlock with Conduit Pro").font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ConduitTheme.accent)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func tile(for puzzle: Puzzle, locked: Bool) -> some View {
        if locked {
            tileLabel(for: puzzle, state: .locked)
                .onTapGesture { showPaywall = true }
                .accessibilityLabel("\(puzzle.name), locked. Requires Conduit Pro.")
                .accessibilityAddTraits(.isButton)
        } else {
            NavigationLink {
                GameView(puzzle: puzzle, context: .level)
            } label: {
                tileLabel(for: puzzle, state: tileState(puzzle.id))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(tileAccessibility(puzzle))
        }
    }

    private enum TileState { case unsolved, solved, perfect, locked }

    private func tileState(_ id: String) -> TileState {
        guard let row = progressRow(id) else { return .unsolved }
        if row.perfect { return .perfect }
        if row.solved { return .solved }
        return .unsolved
    }

    private func tileLabel(for puzzle: Puzzle, state: TileState) -> some View {
        let index = (PuzzleBank.puzzles(in: puzzle.packId).firstIndex(where: { $0.id == puzzle.id }) ?? 0) + 1
        return ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(state == .locked ? ConduitTheme.subtleSurface(scheme) : ConduitTheme.cardSurface(scheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(borderColor(state), lineWidth: state == .unsolved ? 1 : 2)
                )
            VStack(spacing: 4) {
                Text("\(index)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(state == .locked ? ConduitTheme.secondaryText(scheme) : ConduitTheme.primaryText(scheme))
                badge(state)
            }
        }
        .frame(height: 72)
    }

    @ViewBuilder
    private func badge(_ state: TileState) -> some View {
        switch state {
        case .unsolved:
            Text("Play").font(.caption2).foregroundStyle(ConduitTheme.secondaryText(scheme))
        case .solved:
            Image(systemName: "checkmark.circle.fill").font(.caption).foregroundStyle(ConduitTheme.accent)
        case .perfect:
            Image(systemName: "star.fill").font(.caption).foregroundStyle(Color(red: 1, green: 0.78, blue: 0.23))
        case .locked:
            Image(systemName: "lock.fill").font(.caption).foregroundStyle(ConduitTheme.secondaryText(scheme))
        }
    }

    private func borderColor(_ state: TileState) -> Color {
        switch state {
        case .perfect: return Color(red: 1, green: 0.78, blue: 0.23)
        case .solved:  return ConduitTheme.accent
        default:       return ConduitTheme.hairline(scheme)
        }
    }

    private func tileAccessibility(_ puzzle: Puzzle) -> String {
        switch tileState(puzzle.id) {
        case .perfect:  return "\(puzzle.name), solved with perfect coverage"
        case .solved:   return "\(puzzle.name), solved"
        case .unsolved: return "\(puzzle.name), not solved"
        case .locked:   return "\(puzzle.name), locked"
        }
    }

    private func progressRow(_ id: String) -> PuzzleProgress? {
        progress.first { $0.puzzleId == id }
    }
    private func isSolved(_ id: String) -> Bool { progressRow(id)?.solved ?? false }
}

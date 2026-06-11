import SwiftUI
import SwiftData

struct PuzzleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let puzzleId: Int
    @State private var vm: PuzzleViewModel?
    @State private var shakeOffset: CGFloat = 0
    @State private var showShareSheet = false
    @State private var shareText = ""

    var body: some View {
        Group {
            if let vm {
                content(vm: vm)
            } else {
                ProgressView()
                    .task { loadVM() }
            }
        }
        .navigationTitle("Puzzle #\(puzzleId + 1)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func loadVM() {
        let pid = puzzleId
        let puzzle = PuzzleBank.puzzle(for: pid)
        let descriptor = FetchDescriptor<PuzzleAttempt>(
            predicate: #Predicate { $0.puzzleId == pid }
        )
        let attempts = (try? modelContext.fetch(descriptor)) ?? []
        let attempt = attempts.first
        vm = PuzzleViewModel(puzzle: puzzle, attempt: attempt)
    }

    @ViewBuilder
    private func content(vm: PuzzleViewModel) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                // Solved groups
                ForEach(vm.solvedGroups) { group in
                    SolvedGroupView(group: group)
                        .transition(.scale.combined(with: .opacity))
                }

                // Word grid (hidden if all solved or lost)
                if vm.gameState != .won {
                    wordGrid(vm: vm)
                }

                // Revealed answers when lost
                if vm.gameState == .lost {
                    ForEach(vm.revealedGroups) { group in
                        SolvedGroupView(group: group)
                            .opacity(0.7)
                    }
                }

                if vm.gameState == .playing {
                    MistakesView(remaining: vm.mistakesRemaining)
                        .padding(.top, 4)

                    if let hint = vm.oneAwayGroup {
                        Text("One away from: \(hint)!")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.orange)
                            .transition(.opacity)
                    }

                    actionButtons(vm: vm)
                } else {
                    resultBanner(vm: vm)
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 14)
            .padding(.top, 16)
            .animation(reduceMotion ? nil : .spring(response: 0.35), value: vm.solvedGroups.count)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareView(text: shareText)
        }
        .onChange(of: vm.shakeTrigger) { _, _ in
            guard !reduceMotion else { return }
            withAnimation(.default) { shakeOffset = 8 }
            Haptics.error()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.interpolatingSpring(stiffness: 200, damping: 10)) {
                    shakeOffset = 0
                }
            }
        }
    }

    @ViewBuilder
    private func wordGrid(vm: PuzzleViewModel) -> some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible()),
                    GridItem(.flexible()), GridItem(.flexible())]
        LazyVGrid(columns: cols, spacing: 8) {
            ForEach(vm.unsolvedWords, id: \.self) { word in
                WordTileView(
                    word: word,
                    isSelected: vm.selectedWords.contains(word)
                ) {
                    vm.toggleWord(word)
                    Haptics.tap()
                }
            }
        }
        .offset(x: shakeOffset)
    }

    @ViewBuilder
    private func actionButtons(vm: PuzzleViewModel) -> some View {
        HStack(spacing: 12) {
            Button {
                vm.shuffleRemaining()
                Haptics.tap()
            } label: {
                Label("Shuffle", systemImage: "shuffle")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Shuffle remaining words")

            Button {
                vm.deselectAll()
                Haptics.tap()
            } label: {
                Text("Deselect All")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(vm.selectedWords.isEmpty)
            .opacity(vm.selectedWords.isEmpty ? 0.4 : 1)

            Button {
                vm.submitGuess(modelContext: modelContext)
                if vm.gameState == .won { Haptics.success() }
            } label: {
                Text("Submit")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(vm.canSubmit ? WeaveTheme.purple : Color.primary.opacity(0.15))
                    .foregroundStyle(vm.canSubmit ? .white : Color.primary.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(!vm.canSubmit)
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private func resultBanner(vm: PuzzleViewModel) -> some View {
        VStack(spacing: 12) {
            if vm.gameState == .won {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(WeaveTheme.green)
                    .accessibilityHidden(true)
                Text("Excellent!")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                Text("You found all 4 groups.")
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "xmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)
                    .accessibilityHidden(true)
                Text("Better luck next time")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                Text("The answers are revealed above.")
                    .foregroundStyle(.secondary)
            }

            Button {
                shareText = buildShareText(vm: vm)
                showShareSheet = true
            } label: {
                Label("Share Result", systemImage: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(WeaveTheme.purple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .padding(.top, 12)
    }

    private func buildShareText(vm: PuzzleViewModel) -> String {
        let icons = [1: "🟨", 2: "🟩", 3: "🟦", 4: "🟪"]
        var lines = ["Weave #\(puzzleId + 1)"]
        for group in vm.solvedGroups {
            lines.append(icons[group.difficulty, default: "⬜"])
        }
        for group in vm.revealedGroups {
            lines.append(icons[group.difficulty, default: "⬜"])
        }
        let mistakes = 4 - vm.mistakesRemaining
        lines.append("Mistakes: \(mistakes)")
        return lines.joined(separator: "\n")
    }
}

private struct ShareView: UIViewControllerRepresentable {
    let text: String
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

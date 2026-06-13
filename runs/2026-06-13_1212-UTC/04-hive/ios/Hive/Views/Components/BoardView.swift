import SwiftUI

/// The full playable board, shared by Daily, Practice, and Archive. Owns the
/// honeycomb, the current-entry display, the Delete / Shuffle / Enter controls,
/// the rank progress bar, and the found-words list. Persistence and validation
/// live in the supplied `GameViewModel`.
struct BoardView: View {
    @Bindable var vm: GameViewModel
    @Environment(ProStore.self) private var pro
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage("hexLayout") private var hexLayout = true
    @AppStorage("showFoundCount") private var showFoundCount = true

    @State private var showGenius = false
    @State private var showDefinitionFor: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                rankBar
                entryDisplay
                HoneycombView(center: vm.puzzle.center,
                              outer: vm.outerOrder,
                              simple: !hexLayout) { ch in
                    vm.tap(ch)
                }
                .frame(maxWidth: 340)
                .frame(maxWidth: .infinity)
                controls
                foundSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .overlay(alignment: .top) { toastOverlay }
        .animation(reduceMotion ? nil : .spring(duration: 0.3), value: vm.outerOrder)
        .animation(reduceMotion ? nil : .easeInOut, value: vm.toast)
        .onChange(of: vm.justReachedGenius) { _, reached in
            if reached { showGenius = true }
        }
        .sheet(isPresented: $showGenius, onDismiss: { vm.acknowledgeGenius() }) {
            GeniusView(vm: vm)
        }
        .sheet(item: Binding(get: { showDefinitionFor.map { Ident(value: $0) } },
                             set: { showDefinitionFor = $0?.value })) { ident in
            DefinitionView(word: ident.value, isPangram: vm.puzzle.isPangram(ident.value))
        }
    }

    private struct Ident: Identifiable { let value: String; var id: String { value } }

    // MARK: - Rank bar

    private var rankBar: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(vm.rank.name)
                        .font(Theme.rounded(18, .bold)).foregroundStyle(Theme.accent)
                    Spacer()
                    Text("\(vm.score) pts")
                        .font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.surfaceAlt)
                        Capsule().fill(Theme.accent)
                            .frame(width: max(6, geo.size.width * vm.rankProgress))
                    }
                }
                .frame(height: 10)
                .accessibilityElement()
                .accessibilityLabel("Rank \(vm.rank.name), \(vm.score) of \(vm.maxScore) points")
                if let next = vm.nextRank {
                    Text("\(vm.pointsToNext) to \(next.name)")
                        .font(Theme.rounded(13, .medium)).foregroundStyle(Theme.inkSoft)
                } else {
                    Text("Top rank reached")
                        .font(Theme.rounded(13, .bold)).foregroundStyle(Theme.good)
                }
            }
        }
    }

    // MARK: - Entry display

    private var entryDisplay: some View {
        HStack(spacing: 1) {
            if vm.entry.isEmpty {
                Text("Type using the honeycomb")
                    .font(Theme.rounded(22, .bold))
                    .foregroundStyle(Theme.inkFaint)
            } else {
                ForEach(Array(vm.entry.enumerated()), id: \.offset) { _, ch in
                    Text(String(ch).uppercased())
                        .font(Theme.rounded(26, .heavy))
                        .foregroundStyle(colorFor(ch))
                }
            }
        }
        .frame(height: 34)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(vm.entry.isEmpty ? "No letters yet" : "Current word \(vm.entry.uppercased())")
    }

    private func colorFor(_ ch: Character) -> Color {
        if ch == vm.puzzle.center { return Theme.accent }
        return vm.puzzle.letters.contains(ch) ? Theme.ink : Theme.bad
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 12) {
            controlButton(title: "Delete", system: "delete.left") { vm.delete() }
                .disabled(vm.entry.isEmpty)
            controlButton(title: "Shuffle", system: "shuffle") {
                if reduceMotion { vm.shuffle() }
                else { withAnimation(.spring(duration: 0.35)) { vm.shuffle() } }
            }
            Button {
                vm.submit()
            } label: {
                Text("Enter")
                    .font(Theme.rounded(17, .bold))
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(.white)
            }
            .disabled(vm.entry.count < 4)
            .opacity(vm.entry.count < 4 ? 0.5 : 1)
            .accessibilityLabel("Enter word")
        }
    }

    private func controlButton(title: String, system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: system)
                .labelStyle(.iconOnly)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 54, height: 50)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
                .foregroundStyle(Theme.ink)
        }
        .accessibilityLabel(title)
    }

    // MARK: - Found list

    private var foundSection: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Found")
                        .font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink)
                    if showFoundCount {
                        Pill(text: "\(vm.found.count)")
                    }
                    Spacer()
                    Pill(text: "\(vm.pangramsFound)/\(vm.totalPangrams) pangrams",
                         color: Theme.good)
                }
                if vm.found.isEmpty {
                    Text("No words yet. Build one with at least four letters that includes the centre.")
                        .font(Theme.rounded(14, .regular)).foregroundStyle(Theme.inkSoft)
                        .padding(.vertical, 8)
                } else {
                    let cols = [GridItem(.adaptive(minimum: 90), spacing: 8)]
                    LazyVGrid(columns: cols, alignment: .leading, spacing: 8) {
                        ForEach(vm.foundSorted, id: \.self) { word in
                            wordChip(word)
                        }
                    }
                }
            }
        }
    }

    private func wordChip(_ word: String) -> some View {
        let isPangram = vm.puzzle.isPangram(word)
        return Button {
            if pro.isPro { showDefinitionFor = word }
        } label: {
            Text(word.uppercased())
                .font(Theme.rounded(13, .bold))
                .lineLimit(1).minimumScaleFactor(0.7)
                .foregroundStyle(isPangram ? .white : Theme.ink)
                .padding(.horizontal, 10).padding(.vertical, 7)
                .frame(maxWidth: .infinity)
                .background(isPangram ? Theme.accent : Theme.surfaceAlt,
                            in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!pro.isPro)
        .accessibilityLabel(isPangram ? "\(word), pangram" : word)
        .accessibilityHint(pro.isPro ? "Shows a definition peek" : "")
    }

    // MARK: - Toast

    @ViewBuilder private var toastOverlay: some View {
        if let toast = vm.toast {
            Text(toast.message)
                .font(Theme.rounded(15, .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18).padding(.vertical, 10)
                .background(toastColor(toast.kind), in: Capsule())
                .padding(.top, 6)
                .transition(.move(edge: .top).combined(with: .opacity))
                .task(id: toast.id) {
                    try? await Task.sleep(nanoseconds: 1_400_000_000)
                    if vm.toast?.id == toast.id {
                        withAnimation(reduceMotion ? nil : .easeInOut) { vm.toast = nil }
                    }
                }
                .accessibilityAddTraits(.isStaticText)
        }
    }

    private func toastColor(_ kind: GameViewModel.Toast.Kind) -> Color {
        switch kind {
        case .good: return Theme.good
        case .bad: return Theme.bad
        case .pangram: return Theme.accent
        }
    }
}

/// Shown when the player crosses the Genius threshold.
struct GeniusView: View {
    let vm: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "crown.fill")
                    .font(.system(size: 72)).foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("Genius!")
                    .font(Theme.serif(36, .bold)).foregroundStyle(Theme.ink)
                Text("You reached the top rank with \(vm.score) of \(vm.maxScore) points and \(vm.found.count) words. Keep going to find every word.")
                    .font(Theme.rounded(16, .regular)).foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center).padding(.horizontal, 32)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("Keep playing")
                        .font(Theme.rounded(18, .bold))
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 24).padding(.bottom, 24)
            }
        }
    }
}

/// A Pro-only "definition peek". Definitions are intentionally lightweight and
/// fully offline — a short part-of-speech note plus the word's length and
/// pangram status, framed as a glanceable hint rather than a dictionary.
struct DefinitionView: View {
    let word: String
    let isPangram: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                Capsule().fill(Theme.hairline).frame(width: 40, height: 5).padding(.top, 10)
                Text(word.uppercased())
                    .font(Theme.serif(30, .bold)).foregroundStyle(Theme.ink)
                if isPangram {
                    Pill(text: "Pangram", color: Theme.accent)
                }
                Text("\(word.count) letters · uses the centre letter")
                    .font(Theme.rounded(15, .regular)).foregroundStyle(Theme.inkSoft)
                Text("Definition peeks are part of Hive Pro. This word counts toward your score and rank for this puzzle.")
                    .font(Theme.rounded(14, .regular)).foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center).padding(.horizontal, 24)
                Spacer()
            }
            .padding(.bottom, 24)
        }
        .presentationDetents([.height(280)])
    }
}

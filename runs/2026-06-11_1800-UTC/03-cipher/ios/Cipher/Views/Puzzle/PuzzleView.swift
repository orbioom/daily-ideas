import SwiftUI
import SwiftData

@Observable
final class PuzzleViewModel {
    var puzzle: CryptoPuzzle
    var cipher: [Character: Character]
    var encodedText: String
    var userMapping: [Character: Character] = [:]
    var selectedCipherChar: Character? = nil
    var isSolved = false
    var hintsUsed = 0
    var elapsedSeconds = 0
    var isTimerRunning = false

    var progress: PuzzleProgress?

    init(puzzle: CryptoPuzzle) {
        self.puzzle = puzzle
        self.cipher = CipherEngine.makeCipher(seed: puzzle.id)
        self.encodedText = CipherEngine.encode(text: puzzle.quote, cipher: self.cipher)
    }

    var uniqueCipherChars: [Character] {
        let chars = encodedText.filter(\.isLetter).map { $0 }
        var seen = Set<Character>()
        return chars.filter { seen.insert($0).inserted }.sorted()
    }

    var completionPercentage: Double {
        let total = Set(encodedText.filter(\.isLetter)).count
        guard total > 0 else { return 0 }
        let filled = userMapping.keys.filter { uniqueCipherChars.contains($0) }.count
        return Double(filled) / Double(total)
    }

    func assign(real: Character, to cipherChar: Character) {
        let upper = Character(String(real).uppercased())
        // Remove any existing assignment of this real letter to other cipher chars
        userMapping = userMapping.filter { $0.value != upper }
        userMapping[cipherChar] = upper
        checkSolved()
    }

    func clearAssignment(for cipherChar: Character) {
        userMapping.removeValue(forKey: cipherChar)
        isSolved = false
    }

    func useHint() {
        let reverse = Dictionary(uniqueKeysWithValues: cipher.map { ($0.value, $0.key) })
        let unsolved = uniqueCipherChars.filter { userMapping[$0] == nil }
        guard let target = unsolved.randomElement() else { return }
        if let correct = reverse[target] {
            userMapping[target] = correct
            hintsUsed += 1
        }
        checkSolved()
    }

    private func checkSolved() {
        isSolved = CipherEngine.checkSolution(
            encoded: encodedText,
            userMapping: userMapping,
            cipher: cipher
        )
    }

    func save(to context: ModelContext) {
        let p = progress ?? {
            let prog = PuzzleProgress(puzzleId: puzzle.id)
            context.insert(prog)
            return prog
        }()
        p.letterMapping = userMapping
        p.isSolved = isSolved
        if isSolved && p.solvedDate == nil { p.solvedDate = Date() }
        p.hintsUsed = hintsUsed
        p.elapsedSeconds = elapsedSeconds
        p.lastPlayedDate = Date()
        progress = p
    }

    func load(from progress: PuzzleProgress) {
        self.progress = progress
        self.userMapping = progress.letterMapping
        self.hintsUsed = progress.hintsUsed
        self.elapsedSeconds = progress.elapsedSeconds
        self.isSolved = progress.isSolved
    }
}

struct PuzzleView: View {
    @State private var vm: PuzzleViewModel
    @Environment(\.modelContext) private var ctx
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var timer: Timer? = nil
    let puzzle: CryptoPuzzle

    init(puzzle: CryptoPuzzle) {
        self.puzzle = puzzle
        self._vm = State(initialValue: PuzzleViewModel(puzzle: puzzle))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                puzzleHeader
                encodedTextView
                if vm.isSolved {
                    solvedBanner
                        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                } else {
                    letterKeyboard
                }
                Spacer(minLength: 32)
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
        .background(CipherTheme.bg)
        .navigationTitle("Today's Cipher")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Hint") {
                    vm.useHint()
                    vm.save(to: ctx)
                }
                .disabled(vm.isSolved)
                .foregroundStyle(CipherTheme.amber)
                .accessibilityHint("Reveal one letter")
            }
        }
        .onAppear { loadProgress(); startTimer() }
        .onDisappear { timer?.invalidate(); vm.save(to: ctx) }
    }

    @ViewBuilder
    private var puzzleHeader: some View {
        VStack(spacing: 8) {
            Text(puzzle.theme.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(3)
                .foregroundStyle(CipherTheme.amber)

            ProgressView(value: vm.completionPercentage)
                .tint(vm.isSolved ? CipherTheme.solved : CipherTheme.accent)

            HStack {
                Text("\(vm.hintsUsed) hint\(vm.hintsUsed == 1 ? "" : "s") used")
                    .font(.caption)
                    .foregroundStyle(CipherTheme.subtle)
                Spacer()
                Text(timeString)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(CipherTheme.subtle)
            }
        }
    }

    private var timeString: String {
        let m = vm.elapsedSeconds / 60
        let s = vm.elapsedSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    @ViewBuilder
    private var encodedTextView: some View {
        let words = vm.encodedText.components(separatedBy: " ")
        FlowLayout(spacing: 6) {
            ForEach(words.indices, id: \.self) { wi in
                HStack(spacing: 2) {
                    ForEach(Array(words[wi]).indices, id: \.self) { ci in
                        let ch = Array(words[wi])[ci]
                        CipherLetterTile(
                            cipherChar: ch,
                            userChar: ch.isLetter ? vm.userMapping[ch] : nil,
                            isSelected: ch.isLetter && vm.selectedCipherChar == ch,
                            isSolved: vm.isSolved
                        )
                        .onTapGesture {
                            guard ch.isLetter && !vm.isSolved else { return }
                            vm.selectedCipherChar = vm.selectedCipherChar == ch ? nil : ch
                        }
                    }
                }
            }
        }
        .padding()
        .background(CipherTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Encoded quote. \(Int(vm.completionPercentage * 100)) percent decoded.")
    }

    @ViewBuilder
    private var letterKeyboard: some View {
        VStack(spacing: 12) {
            if let sel = vm.selectedCipherChar {
                Text("Decoding: \(String(sel))")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(CipherTheme.accent)
                    .accessibilityLabel("Selected cipher letter: \(sel)")
            } else {
                Text("Tap a letter above to decode it")
                    .font(.caption)
                    .foregroundStyle(CipherTheme.subtle)
            }

            let rows: [[Character]] = [
                Array("QWERTYUIOP"),
                Array("ASDFGHJKL"),
                Array("ZXCVBNM")
            ]

            ForEach(rows.indices, id: \.self) { ri in
                HStack(spacing: 4) {
                    if ri == 2 {
                        Button { if let sel = vm.selectedCipherChar { vm.clearAssignment(for: sel) } } label: {
                            Image(systemName: "delete.left")
                                .font(.caption)
                                .frame(width: 32, height: 36)
                                .background(CipherTheme.card)
                                .foregroundStyle(CipherTheme.text)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .disabled(vm.selectedCipherChar == nil)
                        .accessibilityLabel("Delete assignment")
                    }
                    ForEach(rows[ri], id: \.self) { ch in
                        let isUsed = vm.userMapping.values.contains(ch)
                        Button {
                            guard let sel = vm.selectedCipherChar else { return }
                            vm.assign(real: ch, to: sel)
                            vm.save(to: ctx)
                        } label: {
                            Text(String(ch))
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 32, height: 36)
                                .background(isUsed ? CipherTheme.accent.opacity(0.2) : CipherTheme.card)
                                .foregroundStyle(isUsed ? CipherTheme.accent : CipherTheme.text)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .disabled(vm.selectedCipherChar == nil)
                        .accessibilityLabel("Letter \(ch)\(isUsed ? ", already assigned" : "")")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var solvedBanner: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44))
                .foregroundStyle(CipherTheme.solved)
                .accessibilityHidden(true)

            Text("Decoded!")
                .font(.title2.weight(.bold))
                .foregroundStyle(CipherTheme.text)

            Text("\"\(puzzle.quote.capitalized)\"")
                .font(.body.italic())
                .foregroundStyle(CipherTheme.text)
                .multilineTextAlignment(.center)

            Text("— \(puzzle.author)")
                .font(.caption.weight(.medium))
                .foregroundStyle(CipherTheme.subtle)

            HStack(spacing: 24) {
                VStack {
                    Text(timeString)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(CipherTheme.accent)
                    Text("Time").font(.caption).foregroundStyle(CipherTheme.subtle)
                }
                VStack {
                    Text("\(vm.hintsUsed)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(vm.hintsUsed == 0 ? CipherTheme.solved : CipherTheme.amber)
                    Text("Hints").font(.caption).foregroundStyle(CipherTheme.subtle)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(CipherTheme.card, in: RoundedRectangle(cornerRadius: 20))
    }

    private func loadProgress() {
        let id = puzzle.id
        let fetched = try? ctx.fetch(FetchDescriptor<PuzzleProgress>(
            predicate: #Predicate { $0.puzzleId == id }
        ))
        if let prog = fetched?.first {
            vm.load(from: prog)
        }
    }

    private func startTimer() {
        guard !vm.isSolved else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            vm.elapsedSeconds += 1
        }
    }
}

private struct CipherLetterTile: View {
    let cipherChar: Character
    let userChar: Character?
    let isSelected: Bool
    let isSolved: Bool

    var body: some View {
        if cipherChar.isLetter {
            VStack(spacing: 0) {
                Text(userChar.map(String.init) ?? " ")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isSolved ? CipherTheme.solved : (userChar != nil ? CipherTheme.accent : CipherTheme.text))
                    .frame(width: 20, height: 18)

                Rectangle()
                    .fill(isSelected ? CipherTheme.selected : CipherTheme.subtle.opacity(0.5))
                    .frame(width: 18, height: 1.5)

                Text(String(cipherChar))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSelected ? CipherTheme.selected : CipherTheme.subtle)
                    .frame(width: 20, height: 14)
            }
        } else {
            if cipherChar != " " {
                Text(String(cipherChar))
                    .font(.system(size: 14))
                    .foregroundStyle(CipherTheme.subtle)
                    .frame(width: 8, height: 34)
            } else {
                Spacer().frame(width: 8, height: 34)
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                y += rowHeight + spacing
                x = 0; rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX; rowHeight = 0
            }
            sv.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

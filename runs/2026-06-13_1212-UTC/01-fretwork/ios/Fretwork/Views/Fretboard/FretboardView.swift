import SwiftUI
import SwiftData

struct FretboardView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("tuningID") private var tuningID = Tuning.standardGuitar.id
    @AppStorage("maxFret") private var maxFret = 5
    @State private var vm: FretboardViewModel?
    @State private var savedScore: Int?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if let vm, !vm.isFinished {
                    drill(vm)
                } else if let vm, vm.isFinished {
                    summary(vm)
                } else {
                    setup
                }
            }
            .navigationTitle("Fretboard Trainer")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: Setup (empty/ready state)

    private var setup: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "guitars.fill")
                    .font(.system(size: 56)).foregroundStyle(Theme.accent)
                    .padding(.top, 24).accessibilityHidden(true)
                Text("Name the note")
                    .font(Theme.serif(26, .bold)).foregroundStyle(Theme.ink)
                Text("We light up a string and fret. You pick the note it plays. \(12) questions, then your score.")
                    .font(Theme.rounded(16, .regular)).foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center).padding(.horizontal, 32)

                Card {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tuning").font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.inkSoft)
                            Picker("Tuning", selection: $tuningID) {
                                ForEach(Tuning.all) { Text($0.name).tag($0.id) }
                            }
                            .pickerStyle(.menu).tint(Theme.accent)
                        }
                        Divider().background(Theme.hairline)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Up to fret").font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.inkSoft)
                                Spacer()
                                Text("\(maxFret)").font(Theme.rounded(16, .bold)).foregroundStyle(Theme.accent)
                            }
                            Stepper("Up to fret \(maxFret)", value: $maxFret, in: 3...12)
                                .labelsHidden()
                        }
                    }
                }
                .padding(.horizontal, 16)

                Button {
                    let model = FretboardViewModel(tuningID: tuningID, maxFret: maxFret)
                    model.start(); vm = model; savedScore = nil
                } label: {
                    Text("Start drill").font(Theme.rounded(18, .bold))
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16).padding(.bottom, 28)
            }
        }
    }

    // MARK: Drill

    private func drill(_ vm: FretboardViewModel) -> some View {
        VStack(spacing: 20) {
            ProgressView(value: vm.progress)
                .tint(Theme.accent)
                .padding(.horizontal, 16).padding(.top, 8)
            Text("Question \(vm.index + 1) of \(vm.questionsPerRound)")
                .font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.inkSoft)

            if let q = vm.question {
                MiniFretboard(tuning: vm.tuning, highlight: (q.string, q.fret), maxFret: vm.maxFret)
                    .frame(height: 150).padding(.horizontal, 16)

                Text("Which note is this?")
                    .font(Theme.serif(22, .bold)).foregroundStyle(Theme.ink)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(q.options, id: \.self) { opt in
                        Button { handle(opt, vm) } label: {
                            Text(opt)
                                .font(Theme.serif(24, .bold))
                                .frame(maxWidth: .infinity).padding(.vertical, 18)
                                .background(optionColor(opt, q, vm),
                                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .foregroundStyle(optionText(opt, q, vm))
                        }
                        .disabled(vm.isAnswered)
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: vm.selected)
                    }
                }
                .padding(.horizontal, 16)
            }
            Spacer()
            Button("End drill") { self.vm = nil }
                .font(Theme.rounded(15, .medium)).foregroundStyle(Theme.inkSoft)
                .padding(.bottom, 16)
        }
    }

    private func handle(_ opt: String, _ vm: FretboardViewModel) {
        vm.answer(opt)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            withAnimation(reduceMotion ? nil : .easeInOut) { vm.advance() }
        }
    }

    private func optionColor(_ opt: String, _ q: FretboardViewModel.Question, _ vm: FretboardViewModel) -> Color {
        guard vm.isAnswered else { return Theme.surface }
        if opt == q.correct { return Theme.good }
        if opt == vm.selected { return Theme.bad }
        return Theme.surface
    }
    private func optionText(_ opt: String, _ q: FretboardViewModel.Question, _ vm: FretboardViewModel) -> Color {
        guard vm.isAnswered else { return Theme.ink }
        if opt == q.correct || opt == vm.selected { return .white }
        return Theme.inkSoft
    }

    // MARK: Summary (success state)

    private func summary(_ vm: FretboardViewModel) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: vm.correctCount >= 10 ? "star.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 72)).foregroundStyle(Theme.accent).accessibilityHidden(true)
            Text("\(vm.correctCount) / \(vm.questionsPerRound)")
                .font(Theme.serif(44, .bold)).foregroundStyle(Theme.ink)
            Text(message(vm.correctCount))
                .font(Theme.rounded(17, .regular)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            if let savedScore { Pill(text: "Saved · score \(savedScore)", color: Theme.good) }
            Spacer()
            VStack(spacing: 12) {
                Button {
                    let model = FretboardViewModel(tuningID: tuningID, maxFret: maxFret)
                    model.start(); self.vm = model; savedScore = nil
                } label: {
                    Text("Practise again").font(Theme.rounded(18, .bold))
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(.white)
                }
                Button("Done") { self.vm = nil }
                    .font(Theme.rounded(16, .medium)).foregroundStyle(Theme.inkSoft)
            }
            .padding(.horizontal, 16).padding(.bottom, 28)
        }
        .onAppear { if savedScore == nil { savedScore = vm.save(to: context) } }
    }

    private func message(_ score: Int) -> String {
        switch score {
        case 12: return "Flawless. The fretboard is yours."
        case 10...11: return "Excellent recall — keep widening the fret range."
        case 7...9: return "Solid. A little more and it'll be automatic."
        default: return "Every rep builds the map. Run it again."
        }
    }
}

/// A read-only mini fretboard that lights one position for the drill question.
private struct MiniFretboard: View {
    let tuning: Tuning
    let highlight: (string: Int, fret: Int)
    let maxFret: Int

    var body: some View {
        Canvas { ctx, size in
            let n = tuning.stringCount
            let frets = max(3, maxFret)
            let pad: CGFloat = 18
            let left = pad + 14, right = size.width - pad
            let top = pad, bottom = size.height - pad
            let w = right - left, h = bottom - top
            guard w > 0, h > 0 else { return }
            let sGap = h / CGFloat(n - 1)            // strings horizontal
            let fGap = w / CGFloat(frets)            // frets vertical
            let line = GraphicsContext.Shading.color(Color.dyn(0xCBB48F, 0xB79A6E))
            ctx.fill(Path(roundedRect: CGRect(x: left, y: top, width: w, height: h), cornerRadius: 4),
                     with: .color(Color.dyn(0x3A2A1C, 0x2A1E12)))
            for i in 0...n - 1 {
                let y = top + CGFloat(i) * sGap
                var p = Path(); p.move(to: CGPoint(x: left, y: y)); p.addLine(to: CGPoint(x: right, y: y))
                ctx.stroke(p, with: line, lineWidth: 1.2)
            }
            for j in 0...frets {
                let x = left + CGFloat(j) * fGap
                var p = Path(); p.move(to: CGPoint(x: x, y: top)); p.addLine(to: CGPoint(x: x, y: bottom))
                ctx.stroke(p, with: line, lineWidth: j == 0 ? 5 : 1.2)
            }
            // highlight dot. fret 0 sits just left of the nut (open marker).
            let sy = top + CGFloat(n - 1 - highlight.string) * sGap   // string 0 (low) at bottom
            let dx: CGFloat = highlight.fret == 0
                ? left - 9
                : left + (CGFloat(highlight.fret) - 0.5) * fGap
            let r: CGFloat = 11
            ctx.fill(Path(ellipseIn: CGRect(x: dx - r, y: sy - r, width: r * 2, height: r * 2)),
                     with: .color(Color(hex: 0xB5731F)))
        }
        .accessibilityLabel("String \(highlight.string + 1), fret \(highlight.fret)")
    }
}

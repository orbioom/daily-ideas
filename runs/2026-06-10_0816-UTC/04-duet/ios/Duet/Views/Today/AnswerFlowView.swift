import SwiftUI
import SwiftData

/// The pass-the-phone ritual: partner A answers privately, an interstitial
/// hides the screen during the handoff, partner B answers, then both reveal.
struct AnswerFlowView: View {
    let question: Question
    let existing: Answer?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("nameA") private var nameA = ""
    @AppStorage("nameB") private var nameB = ""

    private enum Step {
        case writeA, handoff, writeB, reveal
    }

    @State private var step: Step = .writeA
    @State private var textA = ""
    @State private var textB = ""
    @State private var confirmLeave = false
    @State private var loaded = false

    private var displayA: String { nameA.isEmpty ? "Partner A" : nameA }
    private var displayB: String { nameB.isEmpty ? "Partner B" : nameB }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                VStack(spacing: 16) {
                    questionHeader
                    switch step {
                    case .writeA: writeView(name: displayA, text: $textA, isFirst: true)
                    case .handoff: handoffView
                    case .writeB: writeView(name: displayB, text: $textB, isFirst: false)
                    case .reveal: revealView
                    }
                    Spacer(minLength: 0)
                }
                .padding(16)
            }
            .navigationTitle("Today's question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if step == .reveal { dismiss() } else { confirmLeave = true }
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close")
                }
            }
            .alert("Pause here?", isPresented: $confirmLeave) {
                Button("Save progress & close") {
                    saveProgress()
                    dismiss()
                }
                Button("Keep going", role: .cancel) {}
            } message: {
                Text("What's written so far is kept — you can finish later today.")
            }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                if let existing {
                    textA = existing.partnerAText
                    textB = existing.partnerBText
                    if !textA.isEmpty { step = .writeB }
                }
            }
        }
        .interactiveDismissDisabled()
    }

    private var questionHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(question.category.rawValue, systemImage: question.category.symbol)
                .font(Brand.mono(12, weight: .medium))
                .foregroundStyle(Brand.text3)
            Text(question.text)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Brand.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .glassCard()
    }

    private func writeView(name: String, text: Binding<String>, isFirst: Bool) -> some View {
        VStack(spacing: 14) {
            Eyebrow(text: "\(name)'s turn")
            TextField("Your answer — honest beats impressive", text: text, axis: .vertical)
                .lineLimit(4...10)
                .padding(14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                .accessibilityLabel("\(name)'s answer")
            Button(isFirst ? "Done — pass to \(displayB)" : "Done — reveal together") {
                guard !text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                Haptics.tap()
                withAnimation(reduceMotion ? nil : Brand.ease()) {
                    step = isFirst ? .handoff : .reveal
                }
                if !isFirst { finishAndSave() }
            }
            .buttonStyle(InkButtonStyle())
            .disabled(text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var handoffView: some View {
        VStack(spacing: 18) {
            Spacer().frame(height: 24)
            Image(systemName: "arrow.left.arrow.right.circle")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Brand.magic)
                .accessibilityHidden(true)
            Text("Hand the phone to \(displayB)")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Brand.text)
            Text("\(displayA)'s answer is hidden until you both finish. No peeking — that's the fun part.")
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("I'm \(displayB) — let me answer") {
                Haptics.tap()
                withAnimation(reduceMotion ? nil : Brand.ease()) { step = .writeB }
            }
            .buttonStyle(InkButtonStyle())
        }
        .glassCard()
    }

    private var revealView: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                StatusDot()
                Text("Revealed together")
                    .font(.caption)
                    .foregroundStyle(Brand.live)
            }
            VStack(alignment: .leading, spacing: 12) {
                answerBlock(name: displayA, text: textA)
                Divider()
                answerBlock(name: displayB, text: textB)
            }
            .glassCard()
            Text("Now talk about the gap between the answers.")
                .font(.caption)
                .foregroundStyle(Brand.text3)
            Button("Done") { dismiss() }
                .buttonStyle(InkButtonStyle())
        }
    }

    private func answerBlock(name: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name.uppercased())
                .font(Brand.mono(11, weight: .medium))
                .tracking(1.2)
                .foregroundStyle(Brand.text3)
            Text(text)
                .font(.body)
                .foregroundStyle(Brand.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name) answered: \(text)")
    }

    // MARK: Persistence

    @State private var created: Answer?

    private func currentAnswer() -> Answer {
        if let existing { return existing }
        if let created { return created }
        let a = Answer(dateKey: DuetEngine.dateKey(), questionID: question.id)
        context.insert(a)
        created = a
        return a
    }

    private func saveProgress() {
        let a = currentAnswer()
        a.partnerAText = textA.trimmingCharacters(in: .whitespacesAndNewlines)
        a.partnerBText = textB.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func finishAndSave() {
        let a = currentAnswer()
        a.partnerAText = textA.trimmingCharacters(in: .whitespacesAndNewlines)
        a.partnerBText = textB.trimmingCharacters(in: .whitespacesAndNewlines)
        a.revealed = true
        Haptics.success()
    }
}

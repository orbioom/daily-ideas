import SwiftUI
import SwiftData

/// The 369 writing ritual. Presented full-screen for one intention; the user
/// writes the affirmation the required number of times for a phase.
struct SessionView: View {
    @Bindable var intention: Intention
    @State var phase: Phase
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("writingMode") private var writingMode = true

    @State private var entry = ""
    @State private var feedback: String?
    @State private var lastWasMatch = false
    @State private var celebrate = false
    @FocusState private var fieldFocused: Bool

    private var count: Int { intention.log(for: Date())?.count(for: phase) ?? 0 }
    private var done: Bool { count >= phase.target }

    var body: some View {
        ZStack {
            Theme.nightSky.ignoresSafeArea()
            VStack(spacing: 22) {
                header
                phasePicker
                Spacer(minLength: 0)
                affirmationCard
                progressDots
                Spacer(minLength: 0)
                if done { completionBlock } else { inputBlock }
            }
            .padding()
        }
        .overlay { if celebrate && !reduceMotion { SparkleBurst() } }
        .onAppear { if writingMode && !done { fieldFocused = true } }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.headline).foregroundStyle(.white.opacity(0.8))
            }
            .accessibilityLabel("Close session")
            Spacer()
            Text("369 Ritual").font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.85))
            Spacer()
            Image(systemName: phase.symbol).foregroundStyle(Theme.accent)
        }
    }

    private var phasePicker: some View {
        HStack(spacing: 8) {
            ForEach(Phase.allCases) { p in
                let c = intention.log(for: Date())?.count(for: p) ?? 0
                Button {
                    Haptics.tap(); phase = p; entry = ""; feedback = nil
                    if writingMode && c < p.target { fieldFocused = true }
                } label: {
                    VStack(spacing: 2) {
                        Text(p.label).font(.caption.weight(.semibold))
                        Text("\(c)/\(p.target)").font(.caption2).monospacedDigit()
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                    .background(phase == p ? Theme.accent.opacity(0.25) : .white.opacity(0.06),
                                in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(phase == p ? Theme.accent : .clear, lineWidth: 1.5))
                    .foregroundStyle(c >= p.target ? Theme.accent : .white)
                }
            }
        }
    }

    private var affirmationCard: some View {
        VStack(spacing: 10) {
            Text("Write this \(phase.target) times")
                .font(.caption).foregroundStyle(.white.opacity(0.65))
            Text(intention.affirmation)
                .font(.system(.title3, design: .serif).weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .scaleEffect(celebrate && !reduceMotion ? 1.04 : 1)
                .animation(reduceMotion ? nil : .spring(response: 0.4), value: celebrate)
        }
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<phase.target, id: \.self) { i in
                Circle()
                    .fill(i < count ? Theme.accent : Color.white.opacity(0.18))
                    .frame(width: 12, height: 12)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(count) of \(phase.target) written")
    }

    @ViewBuilder private var inputBlock: some View {
        VStack(spacing: 12) {
            if writingMode {
                TextField("Write it here…", text: $entry, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .foregroundStyle(.white)
                    .tint(Theme.accent)
                    .padding(14)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                    .focused($fieldFocused)
                    .submitLabel(.done)
                    .onSubmit(submitWriting)
                if let feedback {
                    Text(feedback)
                        .font(.caption)
                        .foregroundStyle(lastWasMatch ? Theme.accent : .white.opacity(0.7))
                }
                Button(action: submitWriting) {
                    Text("Affirm").font(.headline).frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(Theme.accent).controlSize(.large)
                .disabled(entry.trimmingCharacters(in: .whitespaces).isEmpty)
            } else {
                Button(action: tapRep) {
                    Label("I affirmed it", systemImage: "hand.tap.fill")
                        .font(.headline).frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(Theme.accent).controlSize(.large)
                Text("Read the affirmation aloud, feel it, then tap.")
                    .font(.caption).foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private var completionBlock: some View {
        VStack(spacing: 14) {
            Label("\(phase.label) complete", systemImage: "checkmark.seal.fill")
                .font(.headline).foregroundStyle(Theme.accent)
            if let next = nextIncompletePhase {
                Button {
                    Haptics.tap(); phase = next; entry = ""; feedback = nil
                    if writingMode { fieldFocused = true }
                } label: {
                    Text("Continue to \(next.label) (\(next.target)×)")
                        .font(.headline).frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(Theme.accent).controlSize(.large)
            } else {
                Text("Today's 3-6-9 is complete. Beautifully done.")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            Button("Finish") { dismiss() }
                .font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.8))
        }
    }

    private var nextIncompletePhase: Phase? {
        let l = intention.log(for: Date())
        return Phase.allCases.first { ($0 != phase) && ((l?.count(for: $0) ?? 0) < $0.target) }
    }

    // MARK: - Actions

    private func submitWriting() {
        let text = entry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        if TextMatch.matches(text, target: intention.affirmation) {
            registerRep()
            entry = ""
            lastWasMatch = true
            feedback = encouragements.randomElement()
            if !done { fieldFocused = true }
        } else {
            lastWasMatch = false
            feedback = "Close — try writing the full line."
        }
    }

    private func tapRep() {
        guard !done else { return }
        registerRep()
    }

    private func registerRep() {
        let l = ensureLog()
        let newValue = min(l.count(for: phase) + 1, phase.target)
        l.set(newValue, for: phase)
        try? context.save()
        Haptics.rep()
        withAnimation(.spring(response: 0.35)) { celebrate = true }
        Task {
            try? await Task.sleep(for: .milliseconds(450))
            celebrate = false
        }
        if newValue >= phase.target {
            Haptics.success()
            fieldFocused = false
        }
    }

    private func ensureLog() -> PracticeLog {
        if let existing = intention.log(for: Date()) { return existing }
        let l = PracticeLog(day: Date())
        l.intention = intention
        intention.logs.append(l)
        context.insert(l)
        try? context.save()
        return l
    }

    private let encouragements = ["Felt that.", "It's already yours.", "Keep going.", "Beautiful.", "Yes."]
}

/// A brief sparkle flourish on a successful rep. Hidden when Reduce Motion is on.
struct SparkleBurst: View {
    @State private var animate = false
    var body: some View {
        ZStack {
            ForEach(0..<7, id: \.self) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.accent)
                    .offset(x: animate ? CGFloat.random(in: -90...90) : 0,
                            y: animate ? CGFloat.random(in: -110 ... -20) : 0)
                    .opacity(animate ? 0 : 1)
                    .scaleEffect(animate ? 1.4 : 0.4)
            }
        }
        .allowsHitTesting(false)
        .onAppear { withAnimation(.easeOut(duration: 0.45)) { animate = true } }
    }
}

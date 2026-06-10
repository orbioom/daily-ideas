import SwiftUI
import SwiftData

/// Full-screen guided breathing player. A breathing orb expands on the inhale
/// and contracts on the exhale; the affirmation fades in with each new card.
struct PracticePlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let session: PracticeSession

    @State private var index = 0
    @State private var phase: BreathPhase = .inhale
    @State private var orbScale: CGFloat = 0.6
    @State private var paused = false
    @State private var finished = false
    @State private var timer: Timer?

    private let inhale = 4.0
    private let hold = 2.0
    private let exhale = 6.0
    /// Cards advance every two full breaths (~24s) so the words can land.

    enum BreathPhase { case inhale, hold, exhale
        var label: String {
            switch self { case .inhale: "Breathe in"; case .hold: "Hold"; case .exhale: "Breathe out" }
        }
    }

    private var currentTheme: AffirmationTheme {
        guard index < session.items.count else { return .calm }
        return session.items[index].1
    }
    private var currentText: String {
        guard index < session.items.count else { return "" }
        return session.items[index].0
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Brand.mist1, currentTheme.tint.opacity(0.18), Brand.mist3],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .animation(Brand.ease(1.2), value: index)

            VStack {
                topBar
                Spacer()
                orb
                Spacer()
                Text(currentText)
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Brand.text)
                    .padding(.horizontal, 32)
                    .id(index)
                    .transition(.opacity)
                Spacer()
                controls
            }
            .padding()

            if finished { completion }
        }
        .onAppear(perform: start)
        .onDisappear { timer?.invalidate() }
    }

    private var topBar: some View {
        HStack {
            Text("\(min(index + 1, session.items.count)) / \(session.items.count)")
                .font(Brand.mono(15, weight: .medium))
                .foregroundStyle(Brand.text2)
            Spacer()
            Button {
                Haptics.tap(); endEarly()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Brand.text3)
            }
            .accessibilityLabel("End practice")
        }
    }

    private var orb: some View {
        ZStack {
            Circle()
                .fill(currentTheme.tint.opacity(0.18))
                .frame(width: 260, height: 260)
                .scaleEffect(reduceMotion ? 0.9 : orbScale)
            Circle()
                .strokeBorder(currentTheme.tint.opacity(0.5), lineWidth: 2)
                .frame(width: 260, height: 260)
                .scaleEffect(reduceMotion ? 0.9 : orbScale)
            VStack(spacing: 6) {
                Image(systemName: currentTheme.icon)
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(currentTheme.tint)
                Text(paused ? "Paused" : phase.label)
                    .font(.headline)
                    .foregroundStyle(Brand.text2)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(paused ? "Paused" : phase.label)
    }

    private var controls: some View {
        HStack(spacing: 14) {
            Button {
                Haptics.tap(); togglePause()
            } label: {
                Label(paused ? "Resume" : "Pause",
                      systemImage: paused ? "play.fill" : "pause.fill")
            }
            .buttonStyle(GlassButtonStyle())

            Button {
                Haptics.tap(); advance(force: true)
            } label: {
                Label("Skip", systemImage: "forward.fill")
            }
            .buttonStyle(GlassButtonStyle())
        }
    }

    private var completion: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 18) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Brand.magic)
                    .accessibilityHidden(true)
                Text("Practice complete")
                    .font(.title.bold())
                    .foregroundStyle(Brand.text)
                Text("You affirmed \(session.items.count) intentions. Carry them with you.")
                    .font(.body)
                    .foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Button("Done") { dismiss() }
                    .buttonStyle(InkButtonStyle())
                    .padding(.horizontal, 40)
            }
            .padding()
        }
        .transition(.opacity)
    }

    // MARK: - Engine

    private func start() {
        animateBreath()
        scheduleTick()
    }

    private func scheduleTick() {
        timer?.invalidate()
        // A single repeating tick that cycles the breath phases; card advance is
        // counted in full cycles so it is robust regardless of frame rate.
        let cycle = inhale + hold + exhale
        var elapsed = 0.0
        var phaseClock = 0.0
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            guard !paused, !finished else { return }
            elapsed += 0.2
            phaseClock += 0.2
            updatePhase(into: phaseClock.truncatingRemainder(dividingBy: cycle))
            // advance card every two breath cycles
            if elapsed >= cycle * 2 {
                elapsed = 0
                advance(force: false)
            }
        }
    }

    private func updatePhase(into t: Double) {
        let newPhase: BreathPhase
        if t < inhale { newPhase = .inhale }
        else if t < inhale + hold { newPhase = .hold }
        else { newPhase = .exhale }
        if newPhase != phase {
            phase = newPhase
            if phase == .inhale || phase == .exhale { Haptics.selection() }
            animateBreath()
        }
    }

    private func animateBreath() {
        guard !reduceMotion else { orbScale = 0.9; return }
        switch phase {
        case .inhale: withAnimation(.easeInOut(duration: inhale)) { orbScale = 1.0 }
        case .hold: break
        case .exhale: withAnimation(.easeInOut(duration: exhale)) { orbScale = 0.6 }
        }
    }

    private func togglePause() { paused.toggle() }

    private func advance(force: Bool) {
        if index + 1 >= session.items.count {
            complete()
        } else {
            withAnimation(Brand.ease(0.6)) { index += 1 }
            if force { phase = .inhale; animateBreath() }
        }
    }

    private func complete() {
        timer?.invalidate()
        PracticeLog.record(context, count: session.items.count)
        Haptics.success()
        withAnimation(Brand.ease()) { finished = true }
    }

    private func endEarly() {
        timer?.invalidate()
        // Count what was reached so partial practice still nourishes the streak.
        PracticeLog.record(context, count: max(1, index + 1))
        dismiss()
    }
}

#Preview {
    PracticePlayerView(session: PracticeSession(items: [
        ("I trust myself to handle what comes.", .confidence),
        ("This moment is enough.", .calm)
    ]))
    .modelContainer(for: [Affirmation.self, DayLog.self], inMemory: true)
}

import SwiftUI
import SwiftData

struct SessionPlayerView: View {
    let routine: Routine

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("limber.countIn") private var countInSeconds = 3
    @AppStorage("limber.transition") private var transitionSeconds = 5
    @AppStorage("limber.keepAwake") private var keepAwake = true

    private enum Stage { case countIn, hold, transition, done }

    @State private var phases: [MobilityEngine.Phase] = []
    @State private var stage: Stage = .countIn
    @State private var phaseIndex = 0
    @State private var remaining: Double = 0
    @State private var practiced: Double = 0
    @State private var completedHolds = 0
    @State private var paused = false
    @State private var createdLog: SessionLog?

    private let ticker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    private var current: MobilityEngine.Phase? {
        phases.indices.contains(phaseIndex) ? phases[phaseIndex] : nil
    }
    private var next: MobilityEngine.Phase? {
        phases.indices.contains(phaseIndex + 1) ? phases[phaseIndex + 1] : nil
    }
    private var totalProgress: Double {
        guard !phases.isEmpty else { return 0 }
        return Double(phaseIndex) / Double(phases.count)
    }

    var body: some View {
        ZStack {
            (current?.area.tint ?? Brand.live)
                .opacity(0.16)
                .ignoresSafeArea()
            Brand.pageBackground.opacity(0.85).ignoresSafeArea()

            if stage == .done {
                summaryView
            } else {
                playerView
            }
        }
        .onAppear(perform: start)
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .onReceive(ticker) { _ in tick() }
    }

    // MARK: - Player

    private var playerView: some View {
        VStack(spacing: 0) {
            header
            Spacer()
            timerBlock
            Spacer()
            if let n = next, stage == .hold {
                upNext(n)
            }
            controls
        }
        .padding(24)
    }

    private var header: some View {
        HStack {
            Button {
                finish(completed: false)
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(Brand.text2)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("End session")
            Spacer()
            Text("\(min(phaseIndex + 1, phases.count)) / \(phases.count)")
                .font(Brand.mono(15, weight: .medium))
                .foregroundStyle(Brand.text2)
        }
    }

    private var timerBlock: some View {
        VStack(spacing: 26) {
            ProgressRing(progress: stage == .hold ? holdProgress : (stage == .transition ? 1 - remaining / max(1, Double(transitionSeconds)) : 0),
                         lineWidth: 14,
                         tint: current?.area.tint ?? Brand.live,
                         size: 240) {
                AnyView(
                    VStack(spacing: 4) {
                        Text("\(Int(ceil(remaining)))")
                            .font(Brand.mono(64, weight: .bold))
                            .foregroundStyle(Brand.text)
                            .contentTransition(.numericText())
                        Text(stageLabel)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Brand.text3)
                            .textCase(.uppercase)
                    }
                )
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(stageLabel)
            .accessibilityValue("\(Int(ceil(remaining))) seconds")

            VStack(spacing: 8) {
                Text(stage == .countIn ? "Get ready" : (current?.name ?? ""))
                    .font(.title.weight(.bold))
                    .foregroundStyle(Brand.text)
                    .multilineTextAlignment(.center)
                if stage == .hold, let side = current?.sideLabel {
                    Text(side)
                        .font(.headline)
                        .foregroundStyle(current?.area.tint ?? Brand.live)
                }
                if stage == .hold, let detail = current?.detail {
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }
        }
    }

    private func upNext(_ phase: MobilityEngine.Phase) -> some View {
        HStack(spacing: 10) {
            Image(systemName: phase.area.icon)
                .foregroundStyle(phase.area.tint)
                .accessibilityHidden(true)
            Text("Next: \(phase.name)")
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.bottom, 14)
    }

    private var controls: some View {
        HStack(spacing: 14) {
            Button {
                Haptics.tap()
                paused.toggle()
            } label: {
                Label(paused ? "Resume" : "Pause", systemImage: paused ? "play.fill" : "pause.fill")
            }
            .buttonStyle(GlassButtonStyle())

            Button {
                Haptics.selection()
                skip()
            } label: {
                Label("Skip", systemImage: "forward.fill")
            }
            .buttonStyle(GlassButtonStyle())
        }
    }

    private var holdProgress: Double {
        guard let total = current?.seconds, total > 0 else { return 0 }
        return 1 - remaining / Double(total)
    }

    private var stageLabel: String {
        switch stage {
        case .countIn: return "Starting"
        case .hold: return paused ? "Paused" : "Hold"
        case .transition: return "Up next"
        case .done: return "Done"
        }
    }

    // MARK: - Summary

    private var summaryView: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 68))
                .foregroundStyle(Brand.live)
                .accessibilityHidden(true)
            Text("Nicely done")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Brand.text)
            Text("\(MobilityEngine.secondsString(Int(practiced))) · \(completedHolds) holds")
                .font(.headline)
                .foregroundStyle(Brand.text2)

            VStack(spacing: 12) {
                Text("How does your body feel?")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { v in
                        Button {
                            Haptics.selection()
                            createdLog?.feeling = v
                            try? context.save()
                        } label: {
                            Image(systemName: (createdLog?.feeling ?? 0) >= v ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundStyle((createdLog?.feeling ?? 0) >= v ? Brand.warn : Brand.text3)
                        }
                        .accessibilityLabel("\(v) star\(v == 1 ? "" : "s")")
                    }
                }
            }
            .glassCard()
            .padding(.horizontal, 8)

            Spacer()
            Button("Done") {
                Haptics.tap()
                dismiss()
            }
            .buttonStyle(InkButtonStyle())
        }
        .padding(24)
    }

    // MARK: - Timing

    private func start() {
        phases = MobilityEngine.phases(for: routine)
        UIApplication.shared.isIdleTimerDisabled = keepAwake
        if phases.isEmpty {
            finish(completed: false)
            return
        }
        if countInSeconds > 0 {
            stage = .countIn
            remaining = Double(countInSeconds)
        } else {
            startHold()
        }
    }

    private func tick() {
        guard stage != .done, !paused else { return }
        remaining -= 0.1
        if stage == .hold { practiced += 0.1 }
        if remaining <= 0.0001 { advance() }
    }

    private func advance() {
        switch stage {
        case .countIn:
            startHold()
        case .hold:
            completedHolds += 1
            if phaseIndex >= phases.count - 1 {
                finish(completed: true)
            } else if transitionSeconds > 0 {
                stage = .transition
                remaining = Double(transitionSeconds)
            } else {
                phaseIndex += 1
                startHold()
            }
        case .transition:
            phaseIndex += 1
            startHold()
        case .done:
            break
        }
    }

    private func startHold() {
        guard let c = current else { finish(completed: true); return }
        stage = .hold
        remaining = Double(c.seconds)
        Haptics.tap()
    }

    private func skip() {
        switch stage {
        case .countIn:
            startHold()
        case .hold:
            advance()
        case .transition:
            phaseIndex += 1
            startHold()
        case .done:
            break
        }
    }

    private func finish(completed: Bool) {
        guard stage != .done else { return }
        stage = .done
        UIApplication.shared.isIdleTimerDisabled = false
        Haptics.success()
        let areas = Array(Set(phases.map { $0.area }))
        let log = SessionLog(routineName: routine.name,
                             seconds: Int(practiced.rounded()),
                             stretchesDone: completed ? routine.stretchCount : completedHolds,
                             completed: completed,
                             areas: areas)
        context.insert(log)
        try? context.save()
        createdLog = log
        if !completed && practiced < 1 {
            // Nothing practiced — discard the empty log and just leave.
            context.delete(log)
            try? context.save()
            createdLog = nil
            dismiss()
        }
    }
}

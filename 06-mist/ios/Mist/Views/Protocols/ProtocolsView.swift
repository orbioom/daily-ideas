import SwiftUI

struct ProtocolsView: View {
    @State private var selectedProtocol: TherapyProtocol? = nil
    @State private var showRunner = false
    @AppStorage("mistUseFahrenheit") private var useFahrenheit = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(red: 0.05, green: 0.18, blue: 0.22), Color(red: 0.02, green: 0.08, blue: 0.12)],
                              startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        Text("Protocols")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 20)
                            .padding(.horizontal, 20)

                        Text("Expert-designed thermal wellness protocols")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)

                        ForEach(TherapyProtocols.all) { p in
                            protocolCard(p)
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationDestination(item: $selectedProtocol) { p in
                ProtocolDetailView(protocol: p)
            }
        }
    }

    private func protocolCard(_ p: TherapyProtocol) -> some View {
        Button(action: { selectedProtocol = p }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(p.name)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(p.subtitle)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("\(p.totalMinutes) min")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.2, green: 0.85, blue: 0.85))
                        Text("\(p.phases.count) phases")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }

                HStack(spacing: 6) {
                    ForEach(p.phases.prefix(6)) { phase in
                        Capsule()
                            .fill(phase.type.isHot ? Color.orange.opacity(0.5) : Color.cyan.opacity(0.4))
                            .frame(width: max(20, CGFloat(phase.durationSeconds) / 100), height: 8)
                    }
                }

                Text(p.source)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .padding(16)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)
        }
    }
}

struct ProtocolDetailView: View {
    let `protocol`: TherapyProtocol
    @State private var showRunner = false
    @AppStorage("mistUseFahrenheit") private var useFahrenheit = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.05, green: 0.18, blue: 0.22), Color(red: 0.02, green: 0.08, blue: 0.12)],
                          startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Text(`protocol`.name)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(`protocol`.source)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .padding(.top, 20)

                    HStack(spacing: 20) {
                        statBadge(value: "\(`protocol`.totalMinutes) min", label: "Total")
                        statBadge(value: "\(`protocol`.phases.count)", label: "Phases")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Phases")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.horizontal, 20)

                        ForEach(Array(`protocol`.phases.enumerated()), id: \.offset) { idx, phase in
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(phase.type.isHot ? Color.orange.opacity(0.2) : Color.cyan.opacity(0.15))
                                        .frame(width: 38, height: 38)
                                    Image(systemName: phase.type.symbol)
                                        .foregroundStyle(phase.type.isHot ? .orange : .cyan)
                                        .font(.system(size: 16))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(phase.name)
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white)
                                    Text("\(phase.durationDisplay) · \(tempStr(phase.temperatureCelsius))")
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                Spacer()
                                Text("\(idx + 1)")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .padding(.horizontal, 20)
                        }
                    }

                    Button(action: { showRunner = true }) {
                        HStack {
                            Image(systemName: "timer")
                            Text("Start This Protocol")
                        }
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.15, green: 0.7, blue: 0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showRunner) {
            ProtocolRunnerView(protocol: `protocol`)
        }
    }

    private func statBadge(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(width: 100)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func tempStr(_ c: Double) -> String {
        if useFahrenheit { return String(format: "%.0f°F", c * 9/5 + 32) }
        return String(format: "%.0f°C", c)
    }
}

struct ProtocolRunnerView: View {
    let `protocol`: TherapyProtocol
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var currentPhaseIndex = 0
    @State private var phaseElapsed = 0
    @State private var totalElapsed = 0
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var isComplete = false
    @State private var timer: Timer? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("mistUseFahrenheit") private var useFahrenheit = false

    private var currentPhase: ProtocolPhase? {
        guard currentPhaseIndex < `protocol`.phases.count else { return nil }
        return `protocol`.phases[currentPhaseIndex]
    }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            VStack(spacing: 28) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                    Text(`protocol`.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                    Spacer()
                    Text("Phase \(currentPhaseIndex + 1)/\(`protocol`.phases.count)")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                if let phase = currentPhase {
                    VStack(spacing: 12) {
                        Image(systemName: phase.type.symbol)
                            .font(.system(size: 48))
                            .foregroundStyle(phase.type.isHot ? .orange : .cyan)
                        Text(phase.name)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        let remaining = max(0, phase.durationSeconds - phaseElapsed)
                        Text(timeStr(remaining))
                            .font(.system(size: 52, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(.top, 4)

                        if !reduceMotion {
                            let progress = Double(phaseElapsed) / Double(max(1, phase.durationSeconds))
                            ProgressView(value: progress)
                                .tint(phase.type.isHot ? .orange : .cyan)
                                .frame(width: 200)
                                .scaleEffect(x: 1, y: 2)
                                .animation(.linear(duration: 0.4), value: progress)
                        }

                        Text(tempStr(phase.temperatureCelsius))
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                } else if isComplete {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)
                        Text("Protocol Complete!")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Total time: \(timeStr(totalElapsed))")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                Spacer()

                if !isComplete {
                    HStack(spacing: 16) {
                        if !isRunning {
                            Button(action: startPhase) {
                                Text("Start")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color(red: 0.15, green: 0.7, blue: 0.7))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        } else {
                            if isPaused {
                                Button(action: resumePhase) {
                                    Text("Resume")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color(red: 0.15, green: 0.7, blue: 0.7))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            } else {
                                Button(action: pausePhase) {
                                    Text("Pause")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.white.opacity(0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                            Button(action: skipPhase) {
                                Text("Skip")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .frame(width: 80)
                                    .padding(.vertical, 16)
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                } else {
                    Button(action: saveAndDismiss) {
                        Text("Save & Finish")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(red: 0.15, green: 0.7, blue: 0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 32)
                }
                Spacer().frame(height: 48)
            }
        }
    }

    private var bgColor: Color {
        currentPhase?.type.isHot == true
            ? Color(red: 0.18, green: 0.08, blue: 0.04)
            : Color(red: 0.04, green: 0.12, blue: 0.22)
    }

    private func startPhase() {
        isRunning = true
        isPaused = false
        phaseElapsed = 0
        scheduleTimer()
    }

    private func pausePhase() { isPaused = true; timer?.invalidate() }

    private func resumePhase() {
        isPaused = false
        scheduleTimer()
    }

    private func skipPhase() {
        timer?.invalidate()
        advancePhase()
    }

    private func scheduleTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            phaseElapsed += 1
            totalElapsed += 1
            if let phase = currentPhase, phaseElapsed >= phase.durationSeconds {
                timer?.invalidate()
                advancePhase()
            }
        }
    }

    private func advancePhase() {
        phaseElapsed = 0
        if currentPhaseIndex + 1 < `protocol`.phases.count {
            currentPhaseIndex += 1
            isRunning = false
        } else {
            isRunning = false
            isComplete = true
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.success)
        }
    }

    private func saveAndDismiss() {
        let session = TherapySession(
            type: .contrast,
            durationSeconds: totalElapsed,
            temperatureCelsius: 37,
            rounds: `protocol`.phases.count,
            rating: 4,
            notes: "Protocol: \(`protocol`.name)"
        )
        modelContext.insert(session)
        try? modelContext.save()
        dismiss()
    }

    private func timeStr(_ s: Int) -> String { String(format: "%d:%02d", s / 60, s % 60) }
    private func tempStr(_ c: Double) -> String {
        if useFahrenheit { return String(format: "%.0f°F", c * 9/5 + 32) }
        return String(format: "%.0f°C", c)
    }
}

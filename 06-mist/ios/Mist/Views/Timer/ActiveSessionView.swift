import SwiftUI
import SwiftData

@Observable
class ActiveSessionViewModel {
    var isRunning = false
    var isPaused = false
    var elapsedSeconds = 0
    var startDate: Date? = nil
    var pauseAccumulated: TimeInterval = 0
    var pauseStart: Date? = nil
    var rating = 3
    var notes = ""
    var isComplete = false
    var showRatingSheet = false

    let type: TherapyType
    let totalDurationSeconds: Int
    let temperatureCelsius: Double
    let rounds: Int

    private var timer: Timer?

    init(type: TherapyType, durationSeconds: Int, temperatureCelsius: Double, rounds: Int) {
        self.type = type
        self.totalDurationSeconds = durationSeconds
        self.temperatureCelsius = temperatureCelsius
        self.rounds = rounds
    }

    func start() {
        startDate = Date()
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self, let start = self.startDate else { return }
            let raw = Date().timeIntervalSince(start) - self.pauseAccumulated
            self.elapsedSeconds = max(0, Int(raw))
            if self.elapsedSeconds >= self.totalDurationSeconds {
                self.complete()
            }
        }
    }

    func pause() {
        isPaused = true
        pauseStart = Date()
        timer?.invalidate()
    }

    func resume() {
        if let ps = pauseStart {
            pauseAccumulated += Date().timeIntervalSince(ps)
            pauseStart = nil
        }
        isPaused = false
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self, let start = self.startDate else { return }
            let raw = Date().timeIntervalSince(start) - self.pauseAccumulated
            self.elapsedSeconds = max(0, Int(raw))
            if self.elapsedSeconds >= self.totalDurationSeconds {
                self.complete()
            }
        }
    }

    func complete() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isComplete = true
        showRatingSheet = true
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }

    deinit { timer?.invalidate() }

    var progress: Double {
        guard totalDurationSeconds > 0 else { return 0 }
        return min(1.0, Double(elapsedSeconds) / Double(totalDurationSeconds))
    }

    var remaining: Int { max(0, totalDurationSeconds - elapsedSeconds) }
}

struct ActiveSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("mistHapticsEnabled") private var hapticsEnabled = true
    @AppStorage("mistUseFahrenheit") private var useFahrenheit = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var vm: ActiveSessionViewModel

    init(type: TherapyType, durationSeconds: Int, temperatureCelsius: Double, rounds: Int) {
        _vm = State(initialValue: ActiveSessionViewModel(
            type: type,
            durationSeconds: durationSeconds,
            temperatureCelsius: temperatureCelsius,
            rounds: rounds
        ))
    }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack(spacing: 32) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                    Text(vm.type.rawValue)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                    Spacer()
                    Text(tempDisplay)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 12)
                        .frame(width: 240, height: 240)

                    if !reduceMotion {
                        Circle()
                            .trim(from: 0, to: vm.progress)
                            .stroke(
                                AngularGradient(
                                    colors: [ringColor.opacity(0.6), ringColor],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 240, height: 240)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.4), value: vm.progress)
                    }

                    VStack(spacing: 4) {
                        Text(timeString(vm.remaining))
                            .font(.system(size: 54, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                        Text("remaining")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                        if vm.rounds > 1 {
                            Text("Round \(currentRound) of \(vm.rounds)")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }

                Text(elapsedLabel)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))

                Spacer()

                HStack(spacing: 20) {
                    if !vm.isComplete {
                        if !vm.isRunning {
                            Button(action: { vm.start() }) {
                                Label("Start", systemImage: "play.fill")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(ringColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        } else if vm.isPaused {
                            Button(action: { vm.resume() }) {
                                Label("Resume", systemImage: "play.fill")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(ringColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        } else {
                            Button(action: { vm.pause() }) {
                                Label("Pause", systemImage: "pause.fill")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .sheet(isPresented: $vm.showRatingSheet) {
            ratingSheet
                .interactiveDismissDisabled()
        }
    }

    private var ratingSheet: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            VStack(spacing: 24) {
                Text("How was it?")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 32)

                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { i in
                        Button(action: { vm.rating = i }) {
                            Image(systemName: i <= vm.rating ? "star.fill" : "star")
                                .font(.system(size: 32))
                                .foregroundStyle(i <= vm.rating ? .yellow : .white.opacity(0.3))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes (optional)")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                    TextEditor(text: $vm.notes)
                        .scrollContentBackground(.hidden)
                        .background(Color.white.opacity(0.08))
                        .foregroundStyle(.white)
                        .font(.system(size: 15, design: .rounded))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(height: 100)
                }
                .padding(.horizontal, 24)

                Button(action: saveAndDismiss) {
                    Text("Save Session")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(ringColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }

    private var bgColor: Color {
        vm.type.isHot
            ? Color(red: 0.18, green: 0.08, blue: 0.04)
            : Color(red: 0.04, green: 0.12, blue: 0.22)
    }

    private var ringColor: Color {
        vm.type.isHot ? .orange : Color(red: 0.2, green: 0.75, blue: 0.9)
    }

    private var tempDisplay: String {
        if useFahrenheit { return String(format: "%.0f°F", vm.temperatureCelsius * 9/5 + 32) }
        return String(format: "%.0f°C", vm.temperatureCelsius)
    }

    private var elapsedLabel: String {
        "Elapsed: \(timeString(vm.elapsedSeconds))"
    }

    private var currentRound: Int {
        guard vm.rounds > 1 else { return 1 }
        let perRound = vm.totalDurationSeconds / vm.rounds
        if perRound <= 0 { return 1 }
        return min(vm.rounds, vm.elapsedSeconds / perRound + 1)
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func saveAndDismiss() {
        let session = TherapySession(
            type: vm.type,
            durationSeconds: vm.elapsedSeconds,
            temperatureCelsius: vm.temperatureCelsius,
            rounds: vm.rounds,
            rating: vm.rating,
            notes: vm.notes
        )
        modelContext.insert(session)
        try? modelContext.save()
        dismiss()
    }
}

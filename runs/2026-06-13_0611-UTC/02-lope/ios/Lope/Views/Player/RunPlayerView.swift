import SwiftUI
import SwiftData
import UIKit

struct RunPlayerView: View {
    let run: PendingRun
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var engine: RunEngine
    @State private var showComplete = false
    @State private var showEndDialog = false

    init(run: PendingRun) {
        self.run = run
        let voice = UserDefaults.standard.object(forKey: "voiceCues") as? Bool ?? true
        let haptics = UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
        _engine = State(initialValue: RunEngine(workout: run.workout,
                                                voiceEnabled: voice, hapticsEnabled: haptics))
    }

    private var segColor: Color { Theme.segmentColor(engine.currentSegment.kind) }

    var body: some View {
        ZStack {
            segColor.opacity(0.16).ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                Spacer()
                actionView
                Spacer()
                nextView
                controls
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 28)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: engine.currentSegment.kind)
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true; engine.start() }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false; engine.stopWithoutFinishing() }
        .onChange(of: engine.isFinished) { _, finished in if finished { showComplete = true } }
        .sheet(isPresented: $showComplete, onDismiss: { dismiss() }) {
            RunCompleteView(run: run, activeSeconds: engine.activeSeconds)
        }
        .confirmationDialog("End this workout?", isPresented: $showEndDialog, titleVisibility: .visible) {
            Button("Save & finish") { engine.stopWithoutFinishing(); showComplete = true }
            Button("Discard run", role: .destructive) { engine.stopWithoutFinishing(); dismiss() }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("You've run \(Format.clock(engine.activeSeconds)) so far.")
        }
        .statusBarHidden(true)
    }

    private var topBar: some View {
        VStack(spacing: 10) {
            HStack {
                Button { showEndDialog = true } label: {
                    Image(systemName: "xmark").font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.ink).padding(10)
                        .background(Circle().fill(Theme.surface))
                }
                .accessibilityLabel("End workout")
                Spacer()
                VStack(spacing: 0) {
                    Text(run.title).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.inkSoft)
                    Text("\(Format.clock(Int(engine.totalRemaining))) left")
                        .font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Theme.ink)
                        .monospacedDigit()
                }
                Spacer()
                Image(systemName: "xmark").opacity(0).padding(10)   // balance
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceAlt)
                    Capsule().fill(Theme.accent)
                        .frame(width: max(4, geo.size.width * engine.totalProgress))
                }
            }
            .frame(height: 6)
        }
        .padding(.top, 8)
    }

    private var actionView: some View {
        VStack(spacing: 18) {
            ZStack {
                ProgressRing(progress: engine.segmentProgress, lineWidth: 14,
                             color: segColor, track: Theme.surfaceAlt)
                    .frame(width: 250, height: 250)
                VStack(spacing: 4) {
                    Image(systemName: engine.currentSegment.kind.icon)
                        .font(.system(size: 30)).foregroundStyle(segColor)
                        .accessibilityHidden(true)
                    Text(engine.currentSegment.kind.label.uppercased())
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(segColor).tracking(1)
                    Text(Format.clock(Int(engine.segmentRemaining.rounded(.up))))
                        .font(.system(size: 62, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink).monospacedDigit()
                        .contentTransition(.numericText())
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(engine.currentSegment.kind.label), \(Int(engine.segmentRemaining)) seconds remaining")
            if engine.isPaused {
                Text("Paused").font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.coral)
            }
        }
    }

    private var nextView: some View {
        Group {
            if let next = engine.nextSegment {
                HStack(spacing: 8) {
                    Text("NEXT").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.inkFaint)
                    Image(systemName: next.kind.icon).font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.segmentColor(next.kind))
                    Text("\(next.kind.label) · \(Format.clock(next.seconds))")
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.inkSoft)
                }
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Capsule().fill(Theme.surface))
                .padding(.bottom, 24)
            } else {
                Text("Final stretch — finish strong")
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.accent)
                    .padding(.bottom, 24)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 16) {
            controlButton(icon: "stop.fill", label: "End", tint: Theme.coral) { showEndDialog = true }
            Button { engine.togglePause() } label: {
                Image(systemName: engine.isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.accentInk)
                    .frame(width: 84, height: 84)
                    .background(Circle().fill(Theme.accent))
            }
            .accessibilityLabel(engine.isPaused ? "Resume" : "Pause")
            controlButton(icon: "forward.end.fill", label: "Skip", tint: Theme.inkSoft) { engine.skipSegment() }
        }
    }

    private func controlButton(icon: String, label: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 22, weight: .bold)).foregroundStyle(tint)
                    .frame(width: 64, height: 64).background(Circle().fill(Theme.surface))
                Text(label).font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.inkSoft)
            }
        }
        .accessibilityLabel(label)
    }
}

struct RunCompleteView: View {
    let run: PendingRun
    let activeSeconds: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("useMetric") private var useMetric = true

    @State private var rating = 4
    @State private var distanceText = ""
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 54))
                            .foregroundStyle(Theme.accent)
                        Text("Run complete").font(Theme.display(26)).foregroundStyle(Theme.ink)
                        Text(run.title).font(.system(size: 15)).foregroundStyle(Theme.inkSoft)
                    }
                    .padding(.top, 12)

                    HStack(spacing: 10) {
                        StatTile(value: Format.clock(activeSeconds), label: "Active time", color: Theme.accent)
                        StatTile(value: "\(run.workout.runSeconds / 60)", label: "Run minutes")
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("How did it feel?").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.ink)
                        HStack(spacing: 10) {
                            ForEach(1...5, id: \.self) { i in
                                Button { rating = i; Haptics.tap() } label: {
                                    Image(systemName: i <= rating ? "figure.run.circle.fill" : "figure.run.circle")
                                        .font(.system(size: 30))
                                        .foregroundStyle(i <= rating ? Theme.accent : Theme.inkFaint)
                                }
                                .accessibilityLabel("\(i) out of 5")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Distance (optional)").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.ink)
                        HStack {
                            TextField("0.0", text: $distanceText)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 17, design: .rounded))
                            Text(useMetric ? "km" : "mi").foregroundStyle(Theme.inkSoft)
                        }
                        .padding(12).background(RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceAlt))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (optional)").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.ink)
                        TextField("How was the run?", text: $note, axis: .vertical)
                            .lineLimit(2...4)
                            .padding(12).background(RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceAlt))
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.fontWeight(.bold)
                }
            }
        }
    }

    private func save() {
        let meters: Double = {
            let v = Double(distanceText.replacingOccurrences(of: ",", with: ".")) ?? 0
            return useMetric ? v * 1000 : v * 1609.344
        }()
        let log = RunLog(planID: run.plan.id, planName: run.plan.name,
                         weekNumber: run.week.number, sessionIndex: run.sessionIndex,
                         title: run.title, plannedSeconds: run.workout.totalSeconds,
                         activeSeconds: activeSeconds, distanceMeters: max(0, meters),
                         rating: rating, note: note.trimmingCharacters(in: .whitespacesAndNewlines))
        context.insert(log)
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

import SwiftUI
import SwiftData
import UIKit

/// The live, full-screen guided session: a breathing ring that walks through
/// breathe-up, holds and rests. Time accumulates only while running, so pausing
/// is exact.
struct SessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("static.keepAwake") private var keepAwake = true
    @AppStorage("static.phaseCues") private var phaseCues = true
    let table: ApneaTable

    @State private var phases: [Phase] = []
    @State private var elapsed: Double = 0
    @State private var running = false
    @State private var lastTick: Date?
    @State private var lastPhaseIndex = -1
    @State private var showComplete = false
    @State private var notes = ""

    private let ticker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    private var total: Int { phases.last?.start ?? 0 }
    private var currentIndex: Int {
        let e = Int(elapsed)
        for (i, p) in phases.enumerated() where p.kind != .done {
            if e >= p.start && e < p.end { return i }
        }
        return max(0, phases.count - 1)
    }
    private var current: Phase? { phases.indices.contains(currentIndex) ? phases[currentIndex] : nil }
    private var phaseRemaining: Int {
        guard let p = current, p.kind != .done else { return 0 }
        return max(0, p.end - Int(elapsed))
    }
    private var phaseFraction: Double {
        guard let p = current, p.duration > 0 else { return 1 }
        return min(1, max(0, (elapsed - Double(p.start)) / Double(p.duration)))
    }
    private var finished: Bool { Int(elapsed) >= total && total > 0 }

    var body: some View {
        VStack(spacing: 28) {
            header
            ring
            controls
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(phaseBackground.ignoresSafeArea())
        .navigationTitle(table.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("End") { stopAndLog() }.tint(Brand.text2)
            }
        }
        .onAppear {
            phases = TableEngine.phases(table.schedule)
            if keepAwake { UIApplication.shared.isIdleTimerDisabled = true }
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .onReceive(ticker) { _ in tick() }
        .onChange(of: currentIndex) { _, _ in cue() }
        .sheet(isPresented: $showComplete) { completionSheet }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text(phaseLabel.uppercased())
                .font(Brand.mono(14, weight: .semibold)).tracking(3)
                .foregroundStyle(phaseColor)
            if let p = current, p.kind == .hold || p.kind == .rest {
                Text("Round \(p.round) of \(table.rounds)")
                    .font(.subheadline).foregroundStyle(Brand.text2)
            } else if finished {
                Text("Well done").font(.subheadline).foregroundStyle(Brand.text2)
            } else {
                Text("Relax and breathe slowly").font(.subheadline).foregroundStyle(Brand.text2)
            }
        }
        .padding(.top, 12)
    }

    private var ring: some View {
        ZStack {
            Circle().stroke(Brand.hairline, lineWidth: 14)
            Circle()
                .trim(from: 0, to: finished ? 1 : phaseFraction)
                .stroke(phaseColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .linear(duration: 0.1), value: phaseFraction)
            VStack(spacing: 4) {
                Text(finished ? "Done" : TableEngine.clock(phaseRemaining))
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundStyle(Brand.text)
                    .contentTransition(.numericText())
                Text("Total \(TableEngine.clock(Int(elapsed))) / \(TableEngine.clock(total))")
                    .font(Brand.mono(12)).foregroundStyle(Brand.text3)
            }
        }
        .frame(width: 260, height: 260)
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(finished ? "Session complete"
            : "\(phaseLabel), \(phaseRemaining) seconds remaining")
    }

    private var controls: some View {
        HStack(spacing: 14) {
            if finished {
                Button { stopAndLog() } label: {
                    Label("Finish & log", systemImage: "checkmark").frame(maxWidth: .infinity)
                }.buttonStyle(InkButtonStyle())
            } else if running {
                Button { pause() } label: {
                    Label("Pause", systemImage: "pause.fill").frame(maxWidth: .infinity)
                }.buttonStyle(GlassButtonStyle())
            } else {
                Button { start() } label: {
                    Label(elapsed > 0 ? "Resume" : "Begin", systemImage: "play.fill").frame(maxWidth: .infinity)
                }.buttonStyle(InkButtonStyle())
            }
            if !finished {
                Button { skipPhase() } label: {
                    Label("Skip", systemImage: "forward.fill").frame(maxWidth: .infinity)
                }.buttonStyle(GlassButtonStyle())
            }
        }
    }

    private var completionSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill").font(.system(size: 44))
                            .foregroundStyle(Brand.live).accessibilityHidden(true)
                        Text("Session logged").font(.title3.weight(.semibold)).foregroundStyle(Brand.text)
                    }.frame(maxWidth: .infinity).padding(.top, 8)

                    HStack(spacing: 12) {
                        StatTile(value: "\(roundsCompleted())/\(table.rounds)", label: "Rounds")
                        StatTile(value: TableEngine.clock(longestCompletedHold()), label: "Longest hold", accent: Brand.live)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "Notes")
                        TextField("How did it feel?", text: $notes, axis: .vertical)
                            .lineLimit(2...5).textFieldStyle(.roundedBorder)
                    }.glassCard()

                    Button { saveSession() } label: {
                        Label("Save to log", systemImage: "tray.and.arrow.down").frame(maxWidth: .infinity)
                    }.buttonStyle(InkButtonStyle())
                    Button("Discard") { showComplete = false; dismiss() }.buttonStyle(GlassButtonStyle())
                }
                .padding()
            }
            .navigationTitle("Complete")
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
        }
    }

    // MARK: - Timer

    private func tick() {
        guard running, let last = lastTick else { return }
        let now = Date()
        elapsed += now.timeIntervalSince(last)
        lastTick = now
        if finished {
            running = false
            Haptics.success()
            showComplete = true
        }
    }

    private func start() { running = true; lastTick = Date(); Haptics.tap() }
    private func pause() { running = false; lastTick = nil; Haptics.tap() }

    private func skipPhase() {
        guard let p = current, p.kind != .done else { return }
        elapsed = Double(p.end)
        lastTick = Date()
        Haptics.selection()
    }

    private func cue() {
        guard phaseCues, running else { return }
        if let p = current {
            switch p.kind {
            case .hold: Haptics.warning()
            case .rest, .breatheUp: Haptics.success()
            case .done: break
            }
        }
    }

    // MARK: - Logging

    private func roundsCompleted() -> Int {
        let e = Int(elapsed)
        return phases.filter { $0.kind == .hold && $0.end <= e }.count
    }
    private func longestCompletedHold() -> Int {
        let e = Int(elapsed)
        return phases.filter { $0.kind == .hold && $0.end <= e }.map { $0.duration }.max()
            ?? (current?.kind == .hold ? max(0, Int(elapsed) - (current?.start ?? 0)) : 0)
    }

    private func stopAndLog() {
        running = false
        if roundsCompleted() == 0 && Int(elapsed) < TableEngine.breatheUpSeconds {
            // Nothing meaningful happened — just leave.
            dismiss(); return
        }
        showComplete = true
    }

    private func saveSession() {
        let s = ApneaSession(date: Date(), tableName: table.name, type: table.type,
                             roundsPlanned: table.rounds, roundsCompleted: roundsCompleted(),
                             longestHoldSeconds: max(longestCompletedHold(), 0),
                             notes: notes.trimmingCharacters(in: .whitespacesAndNewlines))
        context.insert(s)
        try? context.save()
        Haptics.success()
        showComplete = false
        dismiss()
    }

    // MARK: - Styling

    private var phaseLabel: String {
        guard let p = current else { return "Ready" }
        switch p.kind {
        case .breatheUp: return "Breathe up"
        case .hold: return "Hold"
        case .rest: return "Recover"
        case .done: return "Complete"
        }
    }
    private var phaseColor: Color {
        guard let p = current else { return Brand.text }
        switch p.kind {
        case .breatheUp: return Brand.info
        case .hold: return Brand.warn
        case .rest: return Brand.live
        case .done: return Brand.live
        }
    }
    private var phaseBackground: some View {
        LinearGradient(colors: [Brand.mist1, phaseColor.opacity(0.10), Brand.mist3],
                       startPoint: .top, endPoint: .bottom)
    }
}

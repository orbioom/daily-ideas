import SwiftUI
import SwiftData

struct ProgramDetailView: View {
    let program: TrainingProgram
    var onEdit: (TrainingProgram) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @State private var sessionProgram: TrainingProgram?
    @State private var paywallReason: PaywallReason?
    @State private var showDeleteConfirm = false

    private var engine: SessionEngine { SessionEngine(program: program) }
    private var locked: Bool { !isPro && program.level > Pro.freeMaxLevel }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                breakdownCard
                timelinePreview
                startButton
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !program.isBuiltIn {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            onEdit(program)
                        } label: { Label("Edit", systemImage: "pencil") }
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: { Label("Delete", systemImage: "trash") }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Program options")
                }
            }
        }
        .confirmationDialog("Delete this program?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteProgram() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes \"\(program.name)\". Your session history is kept.")
        }
        .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        .fullScreenCover(item: $sessionProgram) { p in
            SessionPlayerView(program: p)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(program.levelLabel, systemImage: "chart.bar.fill")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.accent)
                Spacer()
                if locked { ProLockChip() }
            }
            Text(program.summary)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 18) {
                metaItem(symbol: "repeat", value: "\(engine.totalReps)", label: "reps")
                metaItem(symbol: "square.stack.3d.up", value: "\(program.sets)", label: program.sets == 1 ? "set" : "sets")
                metaItem(symbol: "clock", value: engine.durationLabel, label: "est.")
            }
        }
        .padding(18)
        .cardSurface()
    }

    private func metaItem(symbol: String, value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: symbol).font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.accent).accessibilityHidden(true)
            Text(value).font(Theme.rounded(18, .bold)).foregroundStyle(Theme.ink)
            Text(label).font(Theme.rounded(11)).foregroundStyle(Theme.inkFaint)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }

    private var breakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Each rep", systemImage: "waveform.path")
            phaseLine(.squeeze, seconds: program.contractSeconds)
            phaseLine(.hold, seconds: program.holdSeconds)
            phaseLine(.relax, seconds: program.relaxSeconds)
            if program.sets > 1 {
                phaseLine(.rest, seconds: program.restSeconds, suffix: "between sets")
            }
        }
        .padding(18)
        .cardSurface()
    }

    @ViewBuilder
    private func phaseLine(_ phase: Phase, seconds: Int, suffix: String? = nil) -> some View {
        if seconds > 0 {
            HStack(spacing: 12) {
                Circle().fill(phase.color).frame(width: 10, height: 10).accessibilityHidden(true)
                Text(phase.label).font(Theme.rounded(15, .medium)).foregroundStyle(Theme.ink)
                if let suffix {
                    Text(suffix).font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
                }
                Spacer()
                Text("\(seconds)s").font(Theme.mono(15)).foregroundStyle(Theme.inkSoft)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(phase.label)\(suffix.map { " \($0)" } ?? ""), \(seconds) seconds")
        }
    }

    private var timelinePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Timeline", systemImage: "rectangle.split.3x1")
            // A horizontal proportional bar of the first set's phases.
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(previewSteps) { step in
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(step.phase.color)
                            .frame(width: barWidth(for: step, total: geo.size.width))
                    }
                }
            }
            .frame(height: 22)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Phase timeline preview")
            legend
        }
        .padding(18)
        .cardSurface()
    }

    /// First-set steps for a compact preview (cap at a reasonable count).
    private var previewSteps: [PhaseStep] {
        Array(engine.steps.prefix(24))
    }

    private func barWidth(for step: PhaseStep, total: CGFloat) -> CGFloat {
        let sum = max(1, previewSteps.reduce(0) { $0 + $1.seconds })
        let spacing = CGFloat(max(0, previewSteps.count - 1)) * 2
        let usable = max(0, total - spacing)
        return max(3, usable * CGFloat(step.seconds) / CGFloat(sum))
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendDot(.squeeze)
            legendDot(.hold)
            legendDot(.relax)
            if program.sets > 1 { legendDot(.rest) }
            Spacer()
        }
    }

    private func legendDot(_ phase: Phase) -> some View {
        HStack(spacing: 5) {
            Circle().fill(phase.color).frame(width: 8, height: 8).accessibilityHidden(true)
            Text(phase.label).font(Theme.rounded(11)).foregroundStyle(Theme.inkSoft)
        }
    }

    private var startButton: some View {
        Group {
            if locked {
                VStack(spacing: 10) {
                    SecondaryButton(title: "Unlock with Tonus Pro", systemImage: "lock.fill") {
                        paywallReason = .lockedProgram
                    }
                    Text("This program is part of Tonus Pro.")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkFaint)
                }
            } else {
                PrimaryButton(title: "Start session", systemImage: "play.fill") {
                    Haptics.tap(enabled: settings.hapticsEnabled)
                    sessionProgram = program
                }
            }
        }
    }

    private func deleteProgram() {
        modelContext.delete(program)
        try? modelContext.save()
        Haptics.tap(enabled: settings.hapticsEnabled)
        dismiss()
    }
}

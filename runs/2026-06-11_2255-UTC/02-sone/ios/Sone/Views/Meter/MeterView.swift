import SwiftUI
import SwiftData
import Charts

struct MeterView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("calibrationOffset") private var calibrationOffset = 100.0
    @AppStorage("keepAwakeWhileMetering") private var keepAwake = true

    @State private var meter = AudioMeter()
    @State private var pendingResult: PendingResult?
    @State private var sessionLabel = ""
    @State private var showSavedToast = false

    struct PendingResult: Identifiable {
        let id = UUID()
        let start: Date
        let duration: TimeInterval
        let avg: Double
        let min: Double
        let max: Double
        let dose: Double
        let samples: [Double]
    }

    var body: some View {
        NavigationStack {
            Group {
                switch meter.state {
                case .idle, .requestingPermission:
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Starting the microphone…")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .denied:
                    deniedView
                case .failed(let message):
                    failedView(message)
                case .running:
                    runningView
                }
            }
            .background(Theme.bgPrimary)
            .navigationTitle("Sone")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        meter.resetStats()
                        Haptics.tap()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .accessibilityLabel("Reset min, average and max")
                    .disabled(meter.state != .running)
                }
            }
        }
        .onAppear {
            meter.calibrationOffset = calibrationOffset
            meter.start()
            if keepAwake { UIApplication.shared.isIdleTimerDisabled = true }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: calibrationOffset) { _, newValue in
            meter.calibrationOffset = newValue
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: if meter.state != .running { meter.start() }
            case .background: if !meter.isRecording { meter.stop() }
            default: break
            }
        }
        .sheet(item: $pendingResult) { result in
            saveSheet(result)
                .presentationDetents([.medium])
        }
    }

    // MARK: - Running

    private var runningView: some View {
        ScrollView {
            VStack(spacing: 18) {
                bigReadout
                sparkline
                statRow
                exposureCard
                recordControls
            }
            .padding(16)
        }
        .overlay(alignment: .top) {
            if showSavedToast {
                Label("Measurement saved", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Theme.bgElevated, in: Capsule())
                    .shadow(radius: 8, y: 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 6)
            }
        }
    }

    private var bigReadout: some View {
        let db = meter.currentDB
        let cls = NoiseMath.classify(db)
        return VStack(spacing: 6) {
            Gauge(value: min(max(db, 20), 130), in: 20...130) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .gaugeStyle(.accessoryLinear)
            .tint(Gradient(colors: [Theme.safe, Theme.caution, Theme.danger]))
            .accessibilityHidden(true)

            Text("\(Int(db.rounded()))")
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.levelColor(db))
                .contentTransition(reduceMotion ? .identity : .numericText())
                .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: Int(db.rounded()))
            Text("dB (est. SPL)")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            Text(cls.label)
                .font(.headline)
                .foregroundStyle(Theme.levelColor(db))
            Text(cls.advice)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .soneCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current level")
        .accessibilityValue("\(Int(db.rounded())) decibels, \(cls.label)")
    }

    private var sparkline: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last 60 seconds")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            if meter.trace.count < 5 {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Collecting samples…")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(height: 110)
                .frame(maxWidth: .infinity)
            } else {
                Chart(Array(meter.trace.enumerated()), id: \.offset) { item in
                    LineMark(
                        x: .value("Sample", item.offset),
                        y: .value("dB", item.element)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Theme.accent)
                    RuleMark(y: .value("Limit", 85))
                        .foregroundStyle(Theme.danger.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
                .chartYScale(domain: 20...130)
                .chartXAxis(.hidden)
                .frame(height: 110)
                .accessibilityLabel("Line chart of the sound level over the last minute")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .soneCard()
    }

    private var statRow: some View {
        HStack(spacing: 12) {
            statTile("MIN", meter.minDB.isFinite ? "\(Int(meter.minDB.rounded()))" : "—", Theme.safe)
            statTile("AVG", meter.averageDB > 0 ? "\(Int(meter.averageDB.rounded()))" : "—", Theme.accent)
            statTile("MAX", meter.maxDB > 0 ? "\(Int(meter.maxDB.rounded()))" : "—", Theme.danger)
        }
    }

    private func statTile(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(color)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .soneCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(value) decibels")
    }

    private var exposureCard: some View {
        let db = meter.currentDB
        return VStack(alignment: .leading, spacing: 8) {
            Label("Safe exposure at this level", systemImage: "ear.badge.waveform")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            if let allowed = NoiseMath.allowedSeconds(at: db) {
                Text(NoiseMath.formatTime(allowed) + " per day")
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.levelColor(db))
                Text("NIOSH limit: 85 dB for 8 h, halving for every +3 dB.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                Text("Unlimited")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.safe)
                Text("Below 80 dB, everyday exposure poses no cumulative risk.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .soneCard()
        .accessibilityElement(children: .combine)
    }

    private var recordControls: some View {
        VStack(spacing: 10) {
            if meter.isRecording, let start = meter.recordingStart {
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    VStack(spacing: 6) {
                        Text("Measuring · \(NoiseMath.formatTime(timeline.date.timeIntervalSince(start)))")
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(Theme.accent)
                        Text(String(format: "Dose this measurement: %.1f%% of daily limit", meter.recordingDose))
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            Button {
                Haptics.tap()
                if meter.isRecording {
                    if let r = meter.endRecording() {
                        pendingResult = PendingResult(start: r.start, duration: r.duration, avg: r.avg,
                                                      min: r.min, max: r.max, dose: r.dose, samples: r.samples)
                    }
                } else {
                    meter.beginRecording()
                }
            } label: {
                Label(meter.isRecording ? "Stop & save measurement" : "Start a measurement",
                      systemImage: meter.isRecording ? "stop.circle.fill" : "record.circle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(meter.isRecording ? Theme.danger : Theme.accent,
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(Color.black.opacity(0.85))
            }
            .accessibilityHint(meter.isRecording
                               ? "Stops measuring and offers to save the result"
                               : "Begins a timed measurement you can save to history")
        }
    }

    // MARK: - Save sheet

    private func saveSheet(_ result: PendingResult) -> some View {
        NavigationStack {
            Form {
                Section("Measurement") {
                    LabeledContent("Average", value: String(format: "%.0f dB", result.avg))
                    LabeledContent("Range", value: String(format: "%.0f–%.0f dB", result.min, result.max))
                    LabeledContent("Duration", value: NoiseMath.formatTime(result.duration))
                    LabeledContent("Daily dose", value: String(format: "%.1f%%", result.dose))
                }
                Section("Label") {
                    TextField("e.g. Office, Concert, Commute", text: $sessionLabel)
                }
            }
            .navigationTitle("Save measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard", role: .destructive) {
                        pendingResult = nil
                        sessionLabel = ""
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        let label = sessionLabel.trimmingCharacters(in: .whitespaces)
                        let session = MeasureSession(
                            startedAt: result.start, duration: result.duration,
                            avgDB: result.avg, minDB: result.min, maxDB: result.max,
                            dosePercent: result.dose,
                            label: label.isEmpty ? "Measurement" : label,
                            samples: result.samples
                        )
                        context.insert(session)
                        pendingResult = nil
                        sessionLabel = ""
                        Haptics.success()
                        withAnimation { showSavedToast = true }
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(2))
                            withAnimation { showSavedToast = false }
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Permission / failure states

    private var deniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.slash")
                .font(.system(size: 44))
                .foregroundStyle(Theme.danger)
                .accessibilityHidden(true)
            Text("Microphone access is off")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Sone needs the microphone to measure sound levels. Audio is analyzed live and never recorded or stored.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if let url = URL(string: UIApplication.openSettingsURLString) {
                Link("Open Settings", destination: url)
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func failedView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44))
                .foregroundStyle(Theme.caution)
                .accessibilityHidden(true)
            Text("Couldn't start the meter")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Try again") { meter.start() }
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

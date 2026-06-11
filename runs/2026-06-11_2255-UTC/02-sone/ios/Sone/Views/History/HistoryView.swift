import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MeasureSession.startedAt, order: .reverse) private var sessions: [MeasureSession]

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "No measurements yet",
                        message: "Start a measurement on the Meter tab — your saved readings, with their full level trace, will live here."
                    )
                } else {
                    List {
                        Section {
                            summaryHeader
                                .listRowBackground(Theme.bgElevated)
                        }
                        Section("Measurements") {
                            ForEach(sessions) { session in
                                NavigationLink(value: session) {
                                    row(session)
                                }
                                .listRowBackground(Theme.bgElevated)
                            }
                            .onDelete { offsets in
                                for index in offsets {
                                    context.delete(sessions[index])
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.bgPrimary)
            .navigationTitle("History")
            .navigationDestination(for: MeasureSession.self) { session in
                SessionDetailView(session: session)
            }
        }
    }

    private var summaryHeader: some View {
        let loudest = sessions.max { $0.maxDB < $1.maxDB }
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(sessions.count)")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.accent)
                Text("saved")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let loudest {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(loudest.maxDB.rounded())) dB")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(Theme.danger)
                    Text("loudest peak (\(loudest.label))")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func row(_ session: MeasureSession) -> some View {
        HStack(spacing: 12) {
            Text("\(Int(session.avgDB.rounded()))")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(Theme.levelColor(session.avgDB))
                .frame(width: 52)
                .accessibilityLabel("\(Int(session.avgDB.rounded())) decibels average")
            VStack(alignment: .leading, spacing: 3) {
                Text(session.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(session.startedAt.formatted(date: .abbreviated, time: .shortened)) · \(NoiseMath.formatTime(session.duration))")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("peak \(Int(session.maxDB.rounded()))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
                Text(String(format: "%.1f%% dose", session.dosePercent))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(session.dosePercent >= 50 ? Theme.danger : Theme.textSecondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct SessionDetailView: View {
    let session: MeasureSession

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Level trace")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    if session.samples.count < 2 {
                        Text("This measurement was too short to chart.")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                            .frame(height: 80)
                    } else {
                        Chart(Array(session.samples.enumerated()), id: \.offset) { item in
                            AreaMark(
                                x: .value("Sample", item.offset),
                                y: .value("dB", item.element)
                            )
                            .foregroundStyle(Theme.accent.opacity(0.18))
                            LineMark(
                                x: .value("Sample", item.offset),
                                y: .value("dB", item.element)
                            )
                            .foregroundStyle(Theme.accent)
                            RuleMark(y: .value("Limit", 85))
                                .foregroundStyle(Theme.danger.opacity(0.6))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                .annotation(position: .top, alignment: .trailing) {
                                    Text("85 dB")
                                        .font(.caption2)
                                        .foregroundStyle(Theme.danger)
                                }
                        }
                        .chartYScale(domain: 20...130)
                        .chartXAxis(.hidden)
                        .frame(height: 200)
                        .accessibilityLabel("Sound level trace for this measurement")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .soneCard()

                VStack(spacing: 0) {
                    detailRow("Started", session.startedAt.formatted(date: .long, time: .shortened))
                    Divider()
                    detailRow("Duration", NoiseMath.formatTime(session.duration))
                    Divider()
                    detailRow("Average (Leq)", String(format: "%.1f dB", session.avgDB))
                    Divider()
                    detailRow("Quietest", String(format: "%.1f dB", session.minDB))
                    Divider()
                    detailRow("Peak", String(format: "%.1f dB", session.maxDB))
                    Divider()
                    detailRow("NIOSH daily dose", String(format: "%.1f%%", session.dosePercent))
                }
                .soneCard()

                let cls = NoiseMath.classify(session.avgDB)
                VStack(alignment: .leading, spacing: 6) {
                    Label(cls.label, systemImage: "ear.badge.waveform")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.levelColor(session.avgDB))
                    Text(cls.advice)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .soneCard()
            }
            .padding(16)
        }
        .background(Theme.bgPrimary)
        .navigationTitle(session.label)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }
}

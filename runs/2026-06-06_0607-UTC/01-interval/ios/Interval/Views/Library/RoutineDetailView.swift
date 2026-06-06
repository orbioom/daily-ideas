import SwiftUI
import SwiftData

/// A routine's detail: its segment structure, totals, recent sessions, and the focal
/// Run action.
struct RoutineDetailView: View {
    @Bindable var routine: Routine
    var onEdit: () -> Void
    var onRun: () -> Void

    private var steps: [TimelineStep] { Timeline.flatten(routine.orderedSegments) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                statsRow

                if !routine.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(routine.note)
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                segmentSection

                timelineSection

                historySection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(Brand.pageBackground)
        .navigationTitle(routine.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit", action: onEdit)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 6) {
                InkButton(title: "Run routine", systemImage: "play.fill",
                          isEnabled: routine.isRunnable, action: onRun)
                if !routine.isRunnable {
                    Text("This routine has no segments yet.")
                        .font(.caption)
                        .foregroundStyle(Brand.rest)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Brand.glassStroke.opacity(0.25)).frame(width: 52, height: 52)
                Image(systemName: routine.glyph)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Brand.text)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(routine.displayName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Brand.text)
                if let last = routine.lastRunAt {
                    Text("Last run \(last.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                } else {
                    Text("Never run")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var statsRow: some View {
        GlassCard {
            HStack(spacing: 0) {
                StatBlock(value: DurationFormat.compact(routine.totalDuration), label: "Total")
                Divider().frame(height: 32)
                StatBlock(value: DurationFormat.compact(routine.totalWorkDuration),
                          label: "Work", tint: Brand.live)
                Divider().frame(height: 32)
                StatBlock(value: "\(routine.stepCount)", label: "Steps")
            }
        }
    }

    private var segmentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Segments")
            if routine.orderedSegments.isEmpty {
                GlassCard {
                    Text("No segments yet. Tap Edit to add prepare, work, rest, and cooldown steps.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(routine.orderedSegments) { segment in
                        SegmentRow(segment: segment)
                    }
                }
            }
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if steps.count > 1 {
                SectionLabel(text: "Expanded timeline · \(steps.count) steps")
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(steps.prefix(40).enumerated()), id: \.element.id) { idx, step in
                            HStack(spacing: 10) {
                                Text("\(idx + 1)")
                                    .font(Brand.mono(12))
                                    .foregroundStyle(Brand.text3)
                                    .frame(width: 24, alignment: .trailing)
                                Circle().fill(step.kind.tint).frame(width: 8, height: 8)
                                    .accessibilityHidden(true)
                                Text(step.headline)
                                    .font(.subheadline)
                                    .foregroundStyle(Brand.text)
                                if step.isRepeated {
                                    Text(step.roundText)
                                        .font(.caption)
                                        .foregroundStyle(Brand.text3)
                                }
                                Spacer(minLength: 0)
                                Text(DurationFormat.clock(step.duration))
                                    .font(Brand.mono(13))
                                    .foregroundStyle(Brand.text2)
                            }
                            .accessibilityElement(children: .combine)
                        }
                        if steps.count > 40 {
                            Text("+ \(steps.count - 40) more")
                                .font(.caption)
                                .foregroundStyle(Brand.text3)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var historySection: some View {
        let sessions = routine.orderedSessions
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Recent runs")
            if sessions.isEmpty {
                GlassCard {
                    Text("No runs yet. Completed runs land here and in History.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(sessions.prefix(5)) { session in
                        SessionRow(session: session, showRoutineName: false)
                    }
                }
            }
        }
    }
}

/// A compact row describing one segment in the builder/detail list.
struct SegmentRow: View {
    var segment: Segment

    var body: some View {
        GlassCard(padding: 12) {
            HStack(spacing: 12) {
                Image(systemName: segment.kind.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(segment.kind.tint)
                    .frame(width: 26)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(segment.displayLabel)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Brand.text)
                    HStack(spacing: 6) {
                        Text(segment.kind.title)
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                        if segment.isInRepeatGroup {
                            Text("· ×\(segment.repeatCount)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Brand.magic)
                        }
                    }
                }
                Spacer(minLength: 0)
                Text(DurationFormat.clock(segment.duration))
                    .font(Brand.mono(15, weight: .medium))
                    .foregroundStyle(Brand.text)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(segment.displayLabel), \(segment.kind.title)")
        .accessibilityValue("\(DurationFormat.compact(segment.duration))" +
                            (segment.isInRepeatGroup ? ", repeats \(segment.repeatCount) times" : ""))
    }
}

#Preview {
    NavigationStack {
        if let routine = SampleData.makeRoutines().first {
            RoutineDetailView(routine: routine, onEdit: {}, onRun: {})
        }
    }
    .intervalPreview()
}

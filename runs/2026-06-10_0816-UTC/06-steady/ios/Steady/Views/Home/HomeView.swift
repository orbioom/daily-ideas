import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ThoughtRecord.createdAt, order: .reverse) private var records: [ThoughtRecord]
    @Query(sort: \MoodLog.date, order: .reverse) private var moods: [MoodLog]

    @AppStorage("showMoodCheckIn") private var showMoodCheckIn = true
    @State private var showReframe = false
    @State private var justLoggedMood = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 14) {
                        reframeCard
                        if showMoodCheckIn { moodCard }
                        if let last = records.first(where: \.isComplete) {
                            lastWinCard(last)
                        }
                        streakCard
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Today")
            .fullScreenCover(isPresented: $showReframe) {
                ReframeFlowView()
            }
        }
    }

    private var reframeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Caught in a thought?")
            Text("Work it through, step by step.")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Brand.text)
            Text("Situation → feeling → thought → thinking trap → evidence → a fairer thought. About three minutes.")
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
            Button {
                Haptics.tap()
                showReframe = true
            } label: {
                Label("Start a thought record", systemImage: "square.and.pencil")
            }
            .buttonStyle(InkButtonStyle())
        }
        .glassCard()
    }

    private var todayMood: MoodLog? {
        moods.first { Calendar.current.isDateInToday($0.date) }
    }

    private var moodCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Quick mood check-in")
            if let mood = todayMood, !justLoggedMood {
                HStack(spacing: 10) {
                    Text(mood.emoji)
                        .font(.title2)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today: \(mood.label)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Brand.text)
                        if !mood.note.isEmpty {
                            Text(mood.note)
                                .font(.caption)
                                .foregroundStyle(Brand.text2)
                        }
                    }
                    Spacer()
                    StatusDot()
                }
                .accessibilityElement(children: .combine)
                Text("Logged — you can tap a face to update it.")
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            } else if justLoggedMood {
                Label("Mood saved.", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(Brand.live)
            }
            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { score in
                    Button {
                        logMood(score)
                    } label: {
                        Text(["", "😟", "🙁", "😐", "🙂", "😄"][score])
                            .font(.system(size: 30))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(todayMood?.score == score ? Brand.live.opacity(0.7) : Brand.glassStroke.opacity(0.4), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(["", "Very low", "Low", "Okay", "Good", "Great"][score])
                    .accessibilityAddTraits(todayMood?.score == score ? .isSelected : [])
                }
            }
        }
        .glassCard()
    }

    private func logMood(_ score: Int) {
        if let mood = todayMood {
            mood.score = score
            mood.date = .now
        } else {
            context.insert(MoodLog(score: score))
        }
        justLoggedMood = true
        Haptics.success()
    }

    private func lastWinCard(_ record: ThoughtRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Your last reframe")
            Text("“\(record.balancedThought)”")
                .font(.subheadline.italic())
                .foregroundStyle(Brand.text)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 14) {
                if record.beliefDrop > 0 {
                    Label("Belief in the thought −\(record.beliefDrop)", systemImage: "arrow.down.right")
                        .font(.caption)
                        .foregroundStyle(Brand.live)
                }
                if record.intensityDrop > 0 {
                    Label("Feeling −\(record.intensityDrop)", systemImage: "arrow.down.right")
                        .font(.caption)
                        .foregroundStyle(Brand.live)
                }
                Spacer()
                Text(record.createdAt, format: .dateTime.day().month())
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
    }

    private var streakCard: some View {
        let insights = InsightEngine.compute(records: records, moods: moods)
        return HStack(spacing: 14) {
            stat("\(insights.streak)", "day streak")
            stat("\(insights.totalReframes)", "reframes")
            stat(insights.avgBeliefDrop > 0 ? "−\(Int(insights.avgBeliefDrop.rounded()))" : "—", "avg belief drop")
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Brand.mono(18, weight: .semibold))
                .foregroundStyle(Brand.text)
            Text(label)
                .font(.caption)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 12)
        .accessibilityElement(children: .combine)
    }
}

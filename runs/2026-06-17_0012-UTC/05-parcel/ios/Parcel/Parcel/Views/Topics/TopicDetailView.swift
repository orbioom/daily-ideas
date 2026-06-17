import SwiftUI
import SwiftData

/// A single topic: blurb, mastery, a launcher, and a browsable question list.
struct TopicDetailView: View {
    let topic: Topic
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context
    @Environment(AppPreferences.self) private var prefs
    @Query private var stats: [QuestionStat]
    @State private var activeSession: ExamSession?
    @State private var browse = false

    private var questions: [Question] { QuestionBank.forTopic(topic) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard
                Button {
                    let s = ExamSession.make(mode: .topic, prefs: prefs, topic: topic, context: context)
                    if !s.isEmpty {
                        Haptics.light(enabled: prefs.hapticsEnabled)
                        activeSession = s
                    }
                } label: {
                    Label("Practice \(questions.count) questions", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())

                Toggle(isOn: $browse.animation()) {
                    Label("Browse questions & answers", systemImage: "list.bullet.rectangle")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textPrimary(scheme))
                }
                .tint(Theme.accent)
                .padding(.horizontal, 4)

                if browse {
                    ForEach(Array(questions.enumerated()), id: \.element.id) { idx, q in
                        BrowseRow(number: idx + 1, question: q)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.background(scheme).ignoresSafeArea())
        .navigationTitle(topic.shortTitle)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $activeSession) { session in
            ExamSessionView(session: session)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: topic.systemImage)
                    .font(.title)
                    .foregroundStyle(topic.chipColor)
                    .accessibilityHidden(true)
                Text(topic.title)
                    .font(Theme.sectionTitle)
                    .foregroundStyle(Theme.textPrimary(scheme))
            }
            Text(topic.blurb)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary(scheme))
                .fixedSize(horizontal: false, vertical: true)
            let m = ProgressEngine.topicMastery(topic, stats: stats)
            VStack(alignment: .leading, spacing: 4) {
                Text("Mastery \(Int((m * 100).rounded()))%")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.textSecondary(scheme))
                MasteryBar(value: m, tint: topic.chipColor, height: 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}

/// A browsable question with its correct answer + explanation revealed.
private struct BrowseRow: View {
    let number: Int
    let question: Question
    @Environment(\.colorScheme) private var scheme
    @State private var revealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(number). \(question.prompt)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.textPrimary(scheme))
                .fixedSize(horizontal: false, vertical: true)
            if revealed {
                VStack(alignment: .leading, spacing: 6) {
                    Label(question.correctOption, systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Theme.success(scheme))
                    Text(question.explanation)
                        .font(.caption)
                        .foregroundStyle(Theme.textPrimary(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                Button("Show answer") { withAnimation { revealed = true } }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(secondary: true)
    }
}

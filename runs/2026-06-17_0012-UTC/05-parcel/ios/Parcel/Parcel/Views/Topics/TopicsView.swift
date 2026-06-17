import SwiftUI
import SwiftData

/// Browse the ten national topics with per-topic mastery and question counts.
struct TopicsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppPreferences.self) private var prefs
    @Query private var stats: [QuestionStat]
    @State private var showPaywall = false

    /// Free users get the first two topics fully; the rest are Pro.
    private func locked(_ index: Int) -> Bool { !prefs.isPro && index >= 2 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    overall
                    ForEach(Array(Topic.allCases.enumerated()), id: \.element) { index, topic in
                        topicRow(topic, locked: locked(index))
                    }
                    Text("Content is national/general for study — verify your state's specific rules separately.")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary(scheme))
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                }
                .padding(16)
            }
            .background(Theme.background(scheme).ignoresSafeArea())
            .navigationTitle("Topics")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var overall: some View {
        let cov = ProgressEngine.coverage(stats: stats, totalQuestions: QuestionBank.all.count)
        return HStack(spacing: 14) {
            Image(systemName: "books.vertical.fill")
                .font(.title2)
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(QuestionBank.all.count) questions · 10 topics")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary(scheme))
                Text("\(Int((cov * 100).rounded()))% of the bank attempted")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary(scheme))
            }
            Spacer()
        }
        .cardSurface()
    }

    @ViewBuilder
    private func topicRow(_ topic: Topic, locked: Bool) -> some View {
        let count = QuestionBank.forTopic(topic).count
        let mastery = ProgressEngine.topicMastery(topic, stats: stats)
        if locked {
            Button { showPaywall = true } label: { rowContent(topic, count: count, mastery: mastery, locked: true) }
                .buttonStyle(.plain)
        } else {
            NavigationLink {
                TopicDetailView(topic: topic)
            } label: {
                rowContent(topic, count: count, mastery: mastery, locked: false)
            }
            .buttonStyle(.plain)
        }
    }

    private func rowContent(_ topic: Topic, count: Int, mastery: Double, locked: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(topic.chipColor.opacity(0.18))
                    .frame(width: 46, height: 46)
                Image(systemName: topic.systemImage)
                    .foregroundStyle(topic.chipColor)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(topic.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary(scheme))
                        .lineLimit(1)
                    if locked { ProBadge() }
                }
                MasteryBar(value: mastery, tint: topic.chipColor)
                Text("\(count) questions · \(Int((mastery * 100).rounded()))% mastery")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary(scheme))
            }
            Spacer(minLength: 4)
            Image(systemName: locked ? "lock.fill" : "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary(scheme))
                .accessibilityHidden(true)
        }
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(topic.title), \(Int((mastery * 100).rounded()))% mastery\(locked ? ", Pro" : "")")
    }
}

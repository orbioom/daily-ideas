import SwiftUI
import SwiftData

struct PracticeListView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @Query private var stats: [QuestionStat]

    @State private var session: ExamSession?
    @State private var showPaywall = false

    private var progress: [CategoryProgress] {
        ProgressEngine.categoryProgress(stats: stats)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if !pro.isPro {
                        ProInlineBanner(message: "Free includes 2 topics. Unlock all 8 with Permit Pro.") {
                            showPaywall = true
                        }
                        .padding(.bottom, 2)
                    }
                    ForEach(progress) { cp in
                        categoryRow(cp)
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Practice by topic")
            .fullScreenCover(item: $session) { s in
                PracticePlayerView(session: s)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private func categoryRow(_ cp: CategoryProgress) -> some View {
        let unlocked = pro.isCategoryUnlocked(cp.category)
        return Button {
            if unlocked {
                Haptics.tap(settings.hapticsEnabled)
                session = ExamEngine.buildCategoryPractice(cp.category, count: 12)
            } else {
                Haptics.warning(settings.hapticsEnabled)
                showPaywall = true
            }
        } label: {
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Theme.accent.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: cp.category.symbol)
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundStyle(Theme.accent)
                        }
                        .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(cp.category.title)
                                .font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
                            Text(cp.category.blurb)
                                .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                                .lineLimit(2)
                        }
                        Spacer()
                        if unlocked {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.inkSoft)
                                .accessibilityHidden(true)
                        } else {
                            ProBadge()
                        }
                    }
                    if unlocked {
                        VStack(alignment: .leading, spacing: 4) {
                            MasteryBar(fraction: Double(cp.mastered) / Double(max(1, cp.totalQuestions)))
                            HStack {
                                Text("\(cp.masteryPercent)% mastered")
                                    .font(Theme.rounded(12, .medium)).foregroundStyle(Theme.accent)
                                Spacer()
                                Text("\(cp.totalQuestions) questions")
                                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(cp.category.title)
        .accessibilityValue(unlocked ? "\(cp.masteryPercent) percent mastered, \(cp.totalQuestions) questions" : "Locked, Pro feature")
        .accessibilityHint(unlocked ? "Starts a practice session" : "Opens the upgrade screen")
    }
}

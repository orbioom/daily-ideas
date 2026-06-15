import SwiftUI
import SwiftData

/// The curriculum: each lesson as a card with personal bests and completion. The first tier
/// (Home Row) is free; the rest gate behind Dactyl Pro.
struct LessonsView: View {
    @AppStorage("isPro") private var isPro = false
    @AppStorage("strictMode") private var strictMode = false
    @Query private var progress: [LessonProgress]

    @State private var paywallReason: PaywallReason?
    @State private var activeLesson: Lesson?

    private var progressByID: [String: LessonProgress] {
        Dictionary(progress.map { ($0.lessonID, $0) }, uniquingKeysWith: { a, _ in a })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    intro
                    ForEach(Curriculum.lessons) { lesson in
                        lessonCard(lesson)
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Lessons")
            .navigationDestination(item: $activeLesson) { lesson in
                TypingSessionView(config: config(for: lesson))
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Build your touch-typing from the home row up. Best WPM and accuracy are saved per lesson.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func lessonCard(_ lesson: Lesson) -> some View {
        let locked = lesson.tier == .pro && !isPro
        let p = progressByID[lesson.id]

        return Button {
            if locked {
                paywallReason = .lockedLesson
            } else {
                activeLesson = lesson
            }
        } label: {
            HStack(spacing: 14) {
                Keycap(label: keycapLabel(for: lesson), size: 48,
                       highlighted: p?.completed == true,
                       tint: Theme.good)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(lesson.title)
                            .font(Theme.rounded(17, .bold))
                            .foregroundStyle(Theme.ink)
                        if locked { ProLockChip() }
                        if p?.completed == true {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.good)
                                .font(.system(size: 14))
                                .accessibilityHidden(true)
                        }
                    }
                    Text(lesson.subtitle)
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                    bestLine(p)
                }
                Spacer(minLength: 0)
                Image(systemName: locked ? "lock.fill" : "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .cardSurface()
        }
        .buttonStyle(PressableScale())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(lesson, locked: locked, progress: p))
        .accessibilityHint(locked ? "Locked. Opens Dactyl Pro." : "Starts the lesson.")
    }

    @ViewBuilder
    private func bestLine(_ p: LessonProgress?) -> some View {
        if let p, p.attempts > 0 {
            HStack(spacing: 10) {
                Label("\(Int(p.bestWPM.rounded())) WPM", systemImage: "bolt.fill")
                Label("\(Int((p.bestAccuracy * 100).rounded()))%", systemImage: "scope")
            }
            .font(Theme.rounded(12, .semibold))
            .foregroundStyle(Theme.accentDeep)
            .padding(.top, 2)
        } else {
            Text("Not started yet")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
                .padding(.top, 2)
        }
    }

    private func keycapLabel(for lesson: Lesson) -> String {
        if let first = lesson.focusKeys.first, first.count == 1 { return first.uppercased() }
        return String(lesson.order + 1)
    }

    private func config(for lesson: Lesson) -> SessionConfig {
        SessionConfig(
            title: lesson.title,
            text: lesson.drillText,
            mode: .lesson,
            strict: strictMode,
            focusKeys: lesson.focusKeys,
            lessonID: lesson.id,
            timeLimit: nil
        )
    }

    private func accessibilityLabel(_ lesson: Lesson, locked: Bool, progress: LessonProgress?) -> String {
        var parts = [lesson.title, lesson.subtitle]
        if locked { parts.append("Pro, locked") }
        if let p = progress, p.attempts > 0 {
            parts.append("Best \(Int(p.bestWPM.rounded())) WPM, \(Int((p.bestAccuracy * 100).rounded())) percent accuracy")
            if p.completed { parts.append("Completed") }
        } else {
            parts.append("Not started")
        }
        return parts.joined(separator: ", ")
    }
}

import SwiftUI

struct LessonsView: View {
    @State private var expandedLesson: Int? = nil

    var body: some View {
        ZStack {
            TypoTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    headerBanner
                    ForEach(Array(TypoLessons.lessons.enumerated()), id: \.offset) { i, lesson in
                        LessonCard(lesson: lesson, index: i, isExpanded: expandedLesson == i) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                expandedLesson = expandedLesson == i ? nil : i
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Lessons")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(TypoTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    var headerBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 28))
                .foregroundStyle(TypoTheme.accent)
            VStack(alignment: .leading, spacing: 4) {
                Text("Typing Tips")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(TypoTheme.textPrimary)
                Text("Learn fundamentals to improve your WPM and accuracy.")
                    .font(.system(size: 13))
                    .foregroundStyle(TypoTheme.textSecondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TypoTheme.surface, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct LessonCard: View {
    let lesson: TypoLesson
    let index: Int
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack {
                    Text("\(index + 1)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 28, height: 28)
                        .background(TypoTheme.accent, in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text(lesson.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(TypoTheme.textPrimary)
                        Text(lesson.subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(TypoTheme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13))
                        .foregroundStyle(TypoTheme.textSecondary)
                }
                .padding(14)
            }

            if isExpanded {
                Divider().background(TypoTheme.background)
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(lesson.tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(TypoTheme.correctGreen)
                                .padding(.top, 1)
                            Text(tip)
                                .font(.system(size: 14))
                                .foregroundStyle(TypoTheme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if let exercise = lesson.exercise {
                        Divider().background(TypoTheme.background)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Practice Exercise")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(TypoTheme.accent)
                            Text(exercise)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(TypoTheme.textSecondary)
                                .padding(10)
                                .background(TypoTheme.background, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(14)
            }
        }
        .background(TypoTheme.surface, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct TypoLesson {
    let title: String
    let subtitle: String
    let tips: [String]
    let exercise: String?
}

enum TypoLessons {
    static let lessons: [TypoLesson] = [
        TypoLesson(
            title: "Home Row Mastery",
            subtitle: "The foundation of fast typing",
            tips: [
                "Place your left fingers on A, S, D, F and right fingers on J, K, L, ;",
                "Keep thumbs resting lightly on the space bar",
                "Return fingers to home row after every keystroke",
                "Your index fingers should feel the small bumps on F and J keys"
            ],
            exercise: "asdf jkl; asdf jkl; fdsa ;lkj fdsa ;lkj"
        ),
        TypoLesson(
            title: "Touch Typing",
            subtitle: "Type without looking at the keyboard",
            tips: [
                "Resist the urge to look at your hands — trust muscle memory",
                "Start slowly and focus on accuracy; speed will come naturally",
                "Cover your hands with a cloth if tempted to peek",
                "Consistent practice of 15 minutes daily builds habits faster than long sessions"
            ],
            exercise: "the and for with that have this from they"
        ),
        TypoLesson(
            title: "Finger Placement",
            subtitle: "Each finger owns specific keys",
            tips: [
                "Left pinky: Q, A, Z; Left ring: W, S, X; Left middle: E, D, C; Left index: R, F, V, T, G, B",
                "Right index: Y, H, N, U, J, M; Right middle: I, K; Right ring: O, L; Right pinky: P, ;, /, '",
                "Reach rather than move your whole hand for distant keys",
                "Practice slow deliberate movements to engrain correct finger paths"
            ],
            exercise: "try the quick brown fox jumped over"
        ),
        TypoLesson(
            title: "Rhythm and Consistency",
            subtitle: "Steady beats fast",
            tips: [
                "Aim for a consistent typing rhythm rather than bursts and pauses",
                "Think of typing like drumming — even tempo is more effective",
                "Slow down on difficult words, then resume your normal pace",
                "Use a metronome app at 60-80 BPM to train rhythm"
            ],
            exercise: "keep calm and type on keep calm and type on"
        ),
        TypoLesson(
            title: "Common Bigrams",
            subtitle: "Master frequent letter pairs",
            tips: [
                "The most common bigrams in English: TH, HE, IN, ER, AN, RE, ON, EN, AT, OU",
                "Practice typing these pairs until they feel like single motions",
                "High-frequency words like 'the', 'and', 'for' should feel automatic",
                "Your hands should 'know' these words without conscious thought"
            ],
            exercise: "the then there therefore their they them"
        ),
        TypoLesson(
            title: "Number Row",
            subtitle: "Mastering numbers without looking",
            tips: [
                "Numbers live directly above the top letter row",
                "Use the same finger as the letter below (1=pinky, 2=ring, etc.)",
                "For numeric-heavy work, consider learning the numpad",
                "Practice number combinations commonly used: dates, times, phone numbers"
            ],
            exercise: "1234 5678 90 2026 1980 42 100 365 24"
        ),
        TypoLesson(
            title: "Accuracy Over Speed",
            subtitle: "The fastest path to high WPM",
            tips: [
                "Every incorrect character you type must be deleted, costing double the time",
                "Target 98%+ accuracy before trying to increase speed",
                "Slow down when your accuracy drops below 95%",
                "Speed follows accuracy — never the other way around"
            ],
            exercise: nil
        ),
        TypoLesson(
            title: "Ergonomics",
            subtitle: "Type comfortably for hours",
            tips: [
                "Keep wrists flat or slightly negative — avoid resting wrists on the desk while typing",
                "Elbows at 90° and shoulders relaxed",
                "Take a 5-minute break every 25 minutes (Pomodoro technique)",
                "Screen should be at eye level to avoid neck strain"
            ],
            exercise: nil
        ),
    ]
}

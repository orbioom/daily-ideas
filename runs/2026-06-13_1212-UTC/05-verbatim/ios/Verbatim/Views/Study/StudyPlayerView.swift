import SwiftUI
import SwiftData

/// The core study loop for one passage: renders it at its current mask level,
/// lets the learner reveal words, then self-grade to update mastery + log a review.
struct StudyPlayerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("passageFontSize") private var fontSizeRaw = PassageFontSize.medium.rawValue

    @State private var model: StudyViewModel

    init(passage: Passage) {
        _model = State(initialValue: StudyViewModel(passage: passage))
    }

    private var fontSize: PassageFontSize { PassageFontSize(rawValue: fontSizeRaw) ?? .medium }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                switch model.phase {
                case .studying: studyingView
                case .grading:  gradingView
                case .done:     doneView
                }
            }
            .navigationTitle(model.passage.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    // MARK: Studying

    private var studyingView: some View {
        VStack(spacing: 0) {
            levelHeader
            ScrollView {
                MaskedPassageView(model: model, fontSize: fontSize)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
            }
            footerButtons
        }
    }

    private var levelHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Pill(text: model.level.displayName)
                Spacer()
                if model.totalHiddenCount > 0 {
                    Text("\(model.revealedCount)/\(model.totalHiddenCount) revealed")
                        .font(Theme.rounded(12, .semibold)).foregroundStyle(Theme.inkSoft)
                }
            }
            Text(model.level.subtitle)
                .font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
                .frame(maxWidth: .infinity, alignment: .leading)
            if model.totalHiddenCount > 0 {
                ProgressView(value: model.revealProgress)
                    .tint(Theme.accent)
                    .accessibilityLabel("Reveal progress")
                    .accessibilityValue("\(Int(model.revealProgress * 100)) percent")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var footerButtons: some View {
        VStack(spacing: 10) {
            if model.totalHiddenCount > 0 && !model.revealAll {
                Button {
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) { model.peekAll() }
                } label: {
                    Label("Reveal all", systemImage: "eye.fill")
                        .font(Theme.rounded(16, .semibold))
                        .frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(Theme.ink)
                }
            }
            Button {
                model.beginGrading()
            } label: {
                Text("How did that go?")
                    .font(Theme.rounded(18, .bold))
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    // MARK: Grading

    private var gradingView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle")
                .font(.system(size: 56)).foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Be honest with yourself")
                .font(Theme.serif(24, .bold)).foregroundStyle(Theme.ink)
            Text("Grade your recall. Verbatim schedules the next review to match.")
                .font(Theme.rounded(15, .regular)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Spacer()
            VStack(spacing: 12) {
                gradeButton(.nailed, "Nailed it", "checkmark.seal.fill", Theme.good,
                            "Move up to \(StudyLevel.forMastery(model.passage.masteryLevel + 1).displayName)")
                gradeButton(.gaps, "Some gaps", "equal.circle.fill", Theme.accent,
                            "Stay at this level")
                gradeButton(.struggled, "Struggled", "arrow.uturn.backward.circle.fill", Theme.bad,
                            "Ease back a level")
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private func gradeButton(_ grade: SpacedRepetition.Grade, _ title: String,
                             _ icon: String, _ color: Color, _ hint: String) -> some View {
        Button {
            model.grade(grade, context: context)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 24)).foregroundStyle(color)
                    .frame(width: 30).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink)
                    Text(hint).font(Theme.rounded(12, .regular)).foregroundStyle(Theme.inkSoft)
                }
                Spacer()
            }
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityHint(hint)
    }

    // MARK: Done

    private var doneView: some View {
        VStack(spacing: 18) {
            Spacer()
            MasteryRing(level: model.passage.masteryLevel, size: 96, lineWidth: 9)
            Text(model.passage.isMastered ? "Memorized." : "Nicely done.")
                .font(Theme.serif(28, .bold)).foregroundStyle(Theme.ink)
            Text(model.passage.isMastered
                 ? "You’ve mastered this passage. Spaced reviews will keep it fresh."
                 : "Next stage: \(model.passage.currentMaskLevel.displayName). \(Fmt.dueDescription(model.passage.nextDue)).")
                .font(Theme.rounded(15, .regular)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Spacer()
            Button {
                Haptics.tap(); dismiss()
            } label: {
                Text("Done")
                    .font(Theme.rounded(18, .bold))
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16).padding(.bottom, 16)
        }
    }
}

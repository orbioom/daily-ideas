import SwiftUI
import SwiftData

/// Full-screen mock-exam simulator: timer, progress, multiple choice / self-check,
/// then a result-review screen.
struct ExamSessionView: View {
    let mode: ExamMode
    let category: CivicsCategory?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppPreferences.self) private var prefs
    @Environment(\.colorScheme) private var scheme

    @Query private var stats: [QuestionStat]

    @State private var model: ExamSessionModel
    @State private var showExitConfirm = false

    init(mode: ExamMode, category: CivicsCategory?) {
        self.mode = mode
        self.category = category
        _model = State(initialValue: ExamSessionModel(mode: mode, category: category))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background(scheme).ignoresSafeArea()
                content
            }
            .navigationTitle(model.mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(model.phase == .finished ? "Done" : "Exit") {
                        if model.phase == .running {
                            showExitConfirm = true
                        } else {
                            dismiss()
                        }
                    }
                }
                if model.phase == .running {
                    ToolbarItem(placement: .topBarTrailing) {
                        Label(model.elapsedFormatted, systemImage: "timer")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(Theme.textSecondary(scheme))
                            .accessibilityLabel("Time elapsed \(model.elapsedFormatted)")
                    }
                }
            }
            .confirmationDialog("Leave this exam? Your progress won\u{2019}t be saved.",
                                isPresented: $showExitConfirm, titleVisibility: .visible) {
                Button("Leave exam", role: .destructive) { dismiss() }
                Button("Keep going", role: .cancel) {}
            }
            .task {
                let byNumber = Dictionary(stats.map { ($0.questionNumber, $0) }, uniquingKeysWith: { a, _ in a })
                await model.start(stats: byNumber)
            }
        }
        .interactiveDismissDisabled(model.phase == .running)
    }

    @ViewBuilder
    private var content: some View {
        switch model.phase {
        case .loading:
            loadingView
        case .failedToBuild(let message):
            buildErrorView(message)
        case .running:
            runningView
        case .finished:
            ExamResultView(model: model, onDone: { dismiss() }, onRetry: retry)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(Theme.accent)
            Text("Preparing your questions\u{2026}")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary(scheme))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Preparing your questions")
    }

    private func buildErrorView(_ message: String) -> some View {
        EmptyStateView(
            systemImage: "exclamationmark.triangle",
            title: "Can\u{2019}t start this exam",
            message: message,
            actionTitle: "Go back",
            action: { dismiss() }
        )
    }

    private var runningView: some View {
        VStack(spacing: 0) {
            ProgressView(value: model.progress)
                .tint(Theme.accent)
                .padding(.horizontal)
                .padding(.top, 8)
                .accessibilityLabel("Question \(model.currentIndex + 1) of \(model.total)")

            if let item = model.current {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        questionHeader(item)
                        if item.isSelfCheck {
                            selfCheckBlock(item)
                        } else {
                            choicesBlock(item)
                        }
                    }
                    .padding()
                }
            } else {
                Spacer()
                EmptyStateView(systemImage: "questionmark", title: "No question",
                               message: "Something went wrong loading this question.")
                Spacer()
            }

            navBar
        }
    }

    private func questionHeader(_ item: ExamItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Question \(model.currentIndex + 1) of \(model.total)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .textCase(.uppercase)
                Spacer()
                Text("Q\(item.question.number)")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary(scheme))
            }
            Text(item.question.prompt)
                .font(Theme.serifTitle(23, weight: .medium))
                .foregroundStyle(Theme.textPrimary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func choicesBlock(_ item: ExamItem) -> some View {
        VStack(spacing: 12) {
            ForEach(Array(item.choices.enumerated()), id: \.offset) { idx, choice in
                let selected = model.currentAnswer?.selectedIndex == idx
                Button {
                    model.selectChoice(idx)
                    Haptics.selection(enabled: prefs.hapticsEnabled)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(selected ? Theme.accent : Theme.textSecondary(scheme))
                            .accessibilityHidden(true)
                        Text(choice)
                            .font(.body)
                            .foregroundStyle(Theme.textPrimary(scheme))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                            .fill(selected ? Theme.accent.opacity(0.12) : Theme.card(scheme))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                            .strokeBorder(selected ? Theme.accent : Theme.hairline(scheme), lineWidth: selected ? 1.5 : 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? [.isSelected] : [])
                .accessibilityLabel(choice)
            }
        }
    }

    private func selfCheckBlock(_ item: ExamItem) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("This answer depends on your state or current officials, so we won\u{2019}t auto-grade it.",
                  systemImage: "info.circle")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary(scheme))

            if let note = item.question.note {
                Text(note)
                    .font(.callout)
                    .foregroundStyle(Theme.textPrimary(scheme))
                    .cardSurface(secondary: true)
            }

            Text("Did you know the answer?")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary(scheme))

            HStack(spacing: 12) {
                selfCheckButton(title: "I knew it", systemImage: "checkmark",
                                isOn: model.currentAnswer?.knewIt == true,
                                tint: Theme.success(scheme)) {
                    model.setSelfCheck(knewIt: true)
                    Haptics.selection(enabled: prefs.hapticsEnabled)
                }
                selfCheckButton(title: "Not sure", systemImage: "questionmark",
                                isOn: model.currentAnswer?.knewIt == false,
                                tint: Theme.federalRed) {
                    model.setSelfCheck(knewIt: false)
                    Haptics.selection(enabled: prefs.hapticsEnabled)
                }
            }
        }
    }

    private func selfCheckButton(title: String, systemImage: String, isOn: Bool, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isOn ? .white : tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: Theme.corner)
                        .fill(isOn ? tint : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.corner)
                        .strokeBorder(tint.opacity(0.6), lineWidth: 1.5)
                )
        }
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    private var navBar: some View {
        HStack(spacing: 12) {
            Button {
                model.goBack()
            } label: {
                Label("Back", systemImage: "chevron.left")
                    .font(.subheadline)
            }
            .disabled(model.currentIndex == 0)
            .foregroundStyle(model.currentIndex == 0 ? Theme.textSecondary(scheme).opacity(0.4) : Theme.accent)

            Spacer()

            if model.isLastItem {
                Button {
                    model.finish(context: context)
                    Haptics.success(enabled: prefs.hapticsEnabled)
                } label: {
                    Text("Finish")
                        .frame(maxWidth: 160)
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: 180)
                .disabled(!(model.currentAnswer?.isAnswered ?? false))
            } else {
                Button {
                    model.advance()
                } label: {
                    Text("Next")
                        .frame(maxWidth: 160)
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: 180)
                .disabled(!(model.currentAnswer?.isAnswered ?? false))
            }
        }
        .padding()
        .background(Theme.card(scheme).opacity(0.6))
    }

    private func retry() {
        let fresh = ExamSessionModel(mode: mode, category: category)
        model = fresh
        Task {
            let byNumber = Dictionary(stats.map { ($0.questionNumber, $0) }, uniquingKeysWith: { a, _ in a })
            await fresh.start(stats: byNumber)
        }
    }
}

import SwiftUI
import SwiftData

/// One question per screen with a 5-point scale, progress, back, resume, computing & reveal.
struct TestRunnerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("userName") private var userName = "You"

    @StateObject private var vm = TestViewModel()
    @Query private var profiles: [Profile]

    /// Whether to ask "resume or restart?" on first appearance.
    @State private var showResumePrompt = false
    @State private var didDecideResume = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if case .asking = vm.phase {
                        Button("Close") { dismiss() }
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                ToolbarItem(placement: .principal) {
                    if case .asking = vm.phase {
                        Text("Question \(vm.index + 1) of \(vm.total)")
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
            }
            .interactiveDismissDisabled(isMidTest)
            .confirmationDialog("Resume your test?",
                                isPresented: $showResumePrompt,
                                titleVisibility: .visible) {
                Button("Resume where I left off") {
                    vm.resume(); didDecideResume = true
                }
                Button("Start over", role: .destructive) {
                    vm.startFresh(); didDecideResume = true
                }
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("You answered \(vm.responses.count) of \(vm.total) questions last time.")
            }
        }
        .onAppear {
            if vm.hasDraft && !didDecideResume {
                showResumePrompt = true
            }
        }
    }

    private var isMidTest: Bool {
        if case .asking = vm.phase { return vm.responses.count > 0 && !vm.canFinish }
        return false
    }

    @ViewBuilder
    private var content: some View {
        switch vm.phase {
        case .asking:
            askingView
        case .computing:
            computingView
        case .finished(let box):
            RevealView(result: box.result) {
                saveAndShow(result: box.result)
            }
        }
    }

    // MARK: - Asking

    private var askingView: some View {
        VStack(spacing: 0) {
            ProgressView(value: vm.progress)
                .tint(Theme.accent)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .accessibilityLabel("Progress")
                .accessibilityValue("\(Int(vm.progress * 100)) percent complete")

            if let item = vm.currentItem {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: item.trait.symbolName)
                        .font(.system(size: 26, weight: .light))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                    Text(item.text)
                        .font(Theme.rounded(26, .bold))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 24)
                        .id(item.id) // re-trigger transition per question
                        .transition(reduceMotion ? .opacity : .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity))
                }
                Spacer()

                LikertScale(selected: vm.answer(for: item)) { value in
                    vm.select(value: value, for: item, hapticsEnabled: settings.hapticsEnabled)
                    maybeFinish()
                }
                .padding(.bottom, 20)

                HStack {
                    Button {
                        vm.goBack()
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .font(Theme.rounded(15, .semibold))
                    }
                    .foregroundStyle(vm.index > 0 ? Theme.accent : Theme.inkFaint)
                    .disabled(vm.index == 0)

                    Spacer()

                    if vm.canFinish {
                        Button {
                            Task { await vm.finish(hapticsEnabled: settings.hapticsEnabled) }
                        } label: {
                            Label("See result", systemImage: "sparkles")
                                .font(Theme.rounded(15, .semibold))
                        }
                        .foregroundStyle(Theme.accent)
                    } else if vm.answer(for: item) != nil && !vm.isOnLastQuestion {
                        Button {
                            vm.advance()
                        } label: {
                            Label("Next", systemImage: "chevron.right")
                                .font(Theme.rounded(15, .semibold))
                                .labelStyle(.titleAndIcon)
                        }
                        .foregroundStyle(Theme.accent)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            } else {
                EmptyStateView(symbol: "exclamationmark.triangle",
                               title: "Something went wrong",
                               message: "We couldn't load this question. Please close and try again.",
                               actionTitle: "Close") { dismiss() }
            }
        }
    }

    private func maybeFinish() {
        // If they just answered the final unanswered item, auto-advance to compute.
        if vm.canFinish && vm.isOnLastQuestion {
            Task { await vm.finish(hapticsEnabled: settings.hapticsEnabled) }
        }
    }

    // MARK: - Computing

    private var computingView: some View {
        VStack(spacing: 22) {
            FacetSpinner()
            Text("Analyzing your facets…")
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.ink)
            Text("Scoring 40 responses across five traits.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Analyzing your responses")
    }

    // MARK: - Save

    private func saveAndShow(result: ScoredResult) {
        let responses = vm.snapshotResponses
        // Find existing primary (the user's own profile) to update; else create.
        if let existing = profiles.first(where: { $0.isPrimary }) {
            existing.apply(result: result, responses: responses)
        } else {
            let name = userName.isEmpty ? "You" : userName
            let profile = Profile(name: name, isPrimary: true, result: result, responses: responses)
            modelContext.insert(profile)
        }
        try? modelContext.save()
        vm.clearDraft()
        dismiss()
    }
}

/// A calm rotating-facet spinner, Reduce-Motion aware.
struct FacetSpinner: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var spin = false

    var body: some View {
        ZStack {
            ForEach(0..<3) { i in
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Theme.accent.opacity(0.5 - Double(i) * 0.12), lineWidth: 3)
                    .frame(width: 70 + CGFloat(i) * 22, height: 70 + CGFloat(i) * 22)
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .animation(reduceMotion ? nil :
                        .linear(duration: 6 - Double(i)).repeatForever(autoreverses: false),
                        value: spin)
            }
            Image(systemName: "circle.hexagongrid.fill")
                .font(.system(size: 34))
                .foregroundStyle(Theme.accent)
        }
        .frame(height: 130)
        .onAppear { spin = true }
        .accessibilityHidden(true)
    }
}

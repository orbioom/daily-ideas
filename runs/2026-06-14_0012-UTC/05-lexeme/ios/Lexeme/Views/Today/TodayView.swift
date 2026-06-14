import SwiftUI
import SwiftData

/// Word of the Day, a due-for-review banner, and the current streak.
struct TodayView: View {
    var goToTab: (AppTab) -> Void
    @Environment(\.modelContext) private var context
    @State private var model = TodayViewModel()
    @State private var showFullEntry = false
    @State private var didMarkAction = false

    private var store: ProgressStore { ProgressStore(context: context) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear { model.load(store: store) }
    }

    @ViewBuilder
    private var content: some View {
        if model.isLoading {
            LoadingView(message: "Choosing today's word...")
        } else {
            ScrollView {
                VStack(spacing: 18) {
                    header
                    if model.dueCount > 0 { dueBanner }
                    if let word = model.wordOfDay {
                        wordCard(word)
                    } else {
                        allLearnedState
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.inkSoft)
                Text("Word of the Day")
                    .font(Theme.serif(24, .bold))
                    .foregroundStyle(Theme.ink)
            }
            Spacer()
            streakBadge
        }
        .padding(.top, 4)
    }

    private var streakBadge: some View {
        VStack(spacing: 1) {
            HStack(spacing: 3) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(model.streak > 0 ? Theme.gold : Theme.inkFaint)
                Text("\(model.streak)")
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
            }
            Text("day streak")
                .font(Theme.rounded(10))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.hairline))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current streak \(model.streak) days")
    }

    private var dueBanner: some View {
        Button {
            Haptics.tap()
            goToTab(.study)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Due for review: \(model.dueCount)")
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(.white)
                    Text("Keep them fresh before you forget.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start review. \(model.dueCount) words due.")
        .accessibilityHint("Opens the Study tab")
    }

    private func wordCard(_ word: VocabWord) -> some View {
        LexemeCard {
            VStack(alignment: .leading, spacing: 16) {
                WordEntryView(word: word, showExample: true)

                if let p = model.todayProgress, p.learned {
                    Label("You marked this as known", systemImage: "checkmark.seal.fill")
                        .font(Theme.rounded(14, .medium))
                        .foregroundStyle(Theme.good)
                } else {
                    HStack(spacing: 12) {
                        Button {
                            Haptics.success()
                            store.markKnown(wordID: word.id)
                            withAnimation { didMarkAction = true }
                            model.load(store: store)
                        } label: {
                            Label("I knew it", systemImage: "checkmark")
                                .font(Theme.rounded(15, .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Theme.good.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .foregroundStyle(Theme.good)
                        }
                        .buttonStyle(.plain)

                        Button {
                            Haptics.tap()
                            store.markLearning(wordID: word.id)
                            withAnimation { didMarkAction = true }
                            model.load(store: store)
                        } label: {
                            Label("Learning", systemImage: "book")
                                .font(Theme.rounded(15, .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .foregroundStyle(Theme.accent)
                        }
                        .buttonStyle(.plain)
                    }

                    if didMarkAction {
                        Text("Added to your review schedule.")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }

                NavigationLink {
                    WordDetailView(word: word)
                } label: {
                    Label("Open full entry", systemImage: "chevron.right")
                        .font(Theme.rounded(14, .medium))
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }

    private var allLearnedState: some View {
        LexemeCard {
            EmptyStateView(systemImage: "checkmark.seal",
                           title: "You've learned them all",
                           message: "Every word in your bank is marked learned. Review them in Study to keep them sharp.",
                           actionTitle: "Go to Study") {
                goToTab(.study)
            }
        }
    }
}

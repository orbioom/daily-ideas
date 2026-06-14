import SwiftUI
import SwiftData

/// Up Next — currently-watching shelf with a big +1 quick-progress button,
/// plus a recently-completed strip.
struct UpNextScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query private var allTitles: [Title]

    private var upNext: [Title] { LibraryEngine.upNext(allTitles) }
    private var completed: [Title] { LibraryEngine.recentlyCompleted(allTitles, limit: 12) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Up Next")
            .navigationDestination(for: Title.self) { title in
                TitleDetailView(title: title)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if upNext.isEmpty && completed.isEmpty {
            EmptyStateView(symbol: "play.circle",
                           title: "Nothing in progress",
                           message: "Set a title to Watching or Reading and it'll show up here with a one-tap +1 button.")
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if upNext.isEmpty {
                        sectionHeader("In progress", "play.circle.fill")
                        Text("Nothing in progress right now. Start a title from your Library or Browse.")
                            .font(Theme.rounded(15))
                            .foregroundStyle(Theme.inkSoft)
                            .padding(.horizontal, 16)
                    } else {
                        sectionHeader("In progress", "play.circle.fill")
                        VStack(spacing: 12) {
                            ForEach(upNext) { title in
                                UpNextRow(title: title)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    if !completed.isEmpty {
                        sectionHeader("Recently completed", "checkmark.seal.fill")
                        completedStrip
                    }
                }
                .padding(.vertical, 12)
            }
        }
    }

    private func sectionHeader(_ text: String, _ symbol: String) -> some View {
        Label(text, systemImage: symbol)
            .font(Theme.display(20, .bold))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 16)
    }

    private var completedStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(completed) { title in
                    NavigationLink(value: title) {
                        VStack(alignment: .leading, spacing: 6) {
                            CoverView(hue: title.coverHue,
                                      kind: title.kind,
                                      initials: title.name.coverInitials,
                                      intensity: settings.accentIntensity)
                                .frame(width: 110, height: 146)
                            Text(title.name)
                                .font(Theme.rounded(12, .semibold))
                                .foregroundStyle(Theme.ink)
                                .lineLimit(2)
                                .frame(width: 110, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                            ScoreChip(score: title.score, hidden: settings.hideScores)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
}

/// A single in-progress row with the big +1 button.
private struct UpNextRow: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Bindable var title: Title
    @State private var justCompleted = false

    var body: some View {
        HStack(spacing: 12) {
            NavigationLink(value: title) {
                CoverView(hue: title.coverHue,
                          kind: title.kind,
                          initials: title.name.coverInitials,
                          intensity: settings.accentIntensity)
                    .frame(width: 64, height: 84)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text(title.name)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text(title.progressLabel)
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                        .monospacedDigit()
                    Text("·")
                        .foregroundStyle(Theme.inkFaint)
                    Text(title.kind.unitNoun.capitalized + (nextLabel == nil ? "" : " \(nextLabel ?? "")"))
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
                ProgressBar(fraction: title.progressFraction)
            }

            Spacer(minLength: 4)

            Button(action: advance) {
                VStack(spacing: 1) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                    Text("1")
                        .font(Theme.rounded(12, .bold))
                }
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(
                    Circle().fill(LinearGradient(colors: [Theme.accent, Theme.violet],
                                                 startPoint: .top, endPoint: .bottom))
                )
            }
            .accessibilityLabel("Advance \(title.name) by one \(title.kind.unitNoun)")
            .accessibilityValue(title.progressLabel)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private var nextLabel: String? {
        guard let total = title.totalUnits, total > 0 else { return nil }
        let next = min(title.progress + 1, total)
        return "\(next)"
    }

    private func advance() {
        let completed = TitleActions.advance(title, by: 1, in: context)
        if completed {
            Haptics.success(settings.hapticsEnabled)
        } else {
            Haptics.tap(settings.hapticsEnabled)
        }
    }
}

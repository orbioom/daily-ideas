import SwiftUI
import SwiftData

struct TodayView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]
    @State private var cycles: PersonalCycles?
    @State private var isLoading = false
    @State private var revealed = false
    @State private var showSettings = false

    private var selected: Profile? {
        ProfileLookup.selected(in: profiles, selectedID: settings.selectedProfileID)
    }

    private var today: Date { Date() }

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                content
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: { Image(systemName: "gearshape.fill") }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
        .task(id: taskKey) { await recompute() }
    }

    /// A composite key so we recompute when profile or settings change.
    private var taskKey: String {
        "\(settings.selectedProfileID)|\(settings.systemRaw)|\(settings.reduceMasterNumbers)"
    }

    @ViewBuilder private var content: some View {
        if profiles.isEmpty {
            EmptyStateView(
                symbol: "moon.stars.fill",
                title: "No profiles yet",
                message: "Add yourself in the Profiles tab to see today's personal numbers and guidance."
            )
        } else if let profile = selected {
            ScrollView {
                VStack(spacing: 18) {
                    if profiles.count > 1 {
                        ProfileChooser(profiles: profiles, selectedID: $settings.selectedProfileID) { _ in
                            Haptics.selection(enabled: settings.hapticsEnabled)
                        }
                        .padding(.top, 4)
                    }

                    dateHeader

                    if isLoading || cycles == nil {
                        ProgressView("Reading the day…")
                            .tint(Theme.accent)
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let cycles {
                        guidanceCard(for: profile, cycles: cycles)
                        cycleRow(cycles: cycles)
                        NavigationLink {
                            ReadingView(profile: profile)
                        } label: {
                            HStack {
                                Image(systemName: "circle.hexagongrid.fill")
                                Text("View \(profile.displayName)'s full chart")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.ink)
                            .padding(16)
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerM))
                            .overlay(RoundedRectangle(cornerRadius: Theme.cornerM).stroke(Theme.hairline, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        } else {
            EmptyStateView(symbol: "person.crop.circle.badge.questionmark",
                           title: "Select a profile",
                           message: "Choose a profile to see today's reading.")
        }
    }

    private var dateHeader: some View {
        VStack(spacing: 4) {
            Text(today, format: .dateTime.weekday(.wide))
                .font(Theme.serif(.title2))
                .foregroundStyle(Theme.ink)
            Text(today, format: .dateTime.day().month(.wide).year())
                .font(Theme.rounded(14, .medium))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func guidanceCard(for profile: Profile, cycles: PersonalCycles) -> some View {
        let day = cycles.day.value
        let meaning = InterpretationLibrary.meaning(for: day)
        let guidance = DailyGuidance.line(forPersonalDay: day, on: today)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Personal Day")
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.accent)
                    Text(meaning.title)
                        .font(Theme.serif(.title3))
                        .foregroundStyle(.white)
                }
                Spacer()
                NumberGlyph(value: day, size: 60, isMaster: cycles.day.isMaster)
                    .scaleEffect(revealed || reduceMotion ? 1 : 0.6)
                    .opacity(revealed || reduceMotion ? 1 : 0)
            }
            Divider().overlay(Color.white.opacity(0.15))
            Text(guidance)
                .font(Theme.serif(.body))
                .foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                ForEach(meaning.keywords.prefix(3), id: \.self) { kw in
                    TagPill(text: kw, tint: Theme.accent)
                }
            }
        }
        .padding(20)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: Theme.cornerL))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerL)
                .stroke(Theme.accent.opacity(0.4), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Personal Day number \(day), \(meaning.title). \(guidance)")
        .onAppear { triggerReveal() }
    }

    private func cycleRow(cycles: PersonalCycles) -> some View {
        HStack(spacing: 12) {
            cycleChip(title: "Personal Year", result: cycles.year, symbol: "calendar")
            cycleChip(title: "Personal Month", result: cycles.month, symbol: "calendar.day.timeline.left")
            cycleChip(title: "Personal Day", result: cycles.day, symbol: "sun.max.fill")
        }
    }

    private func cycleChip(title: String, result: ReductionResult, symbol: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 16))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("\(result.value)")
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
            Text(title)
                .font(Theme.rounded(11, .medium))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerM))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerM).stroke(Theme.hairline, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(result.value)")
    }

    private func triggerReveal() {
        guard !revealed else { return }
        if reduceMotion {
            revealed = true
        } else {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.15)) {
                revealed = true
            }
        }
        Haptics.impact(.soft, enabled: settings.hapticsEnabled)
    }

    @MainActor
    private func recompute() async {
        guard let profile = selected else {
            cycles = nil
            return
        }
        isLoading = true
        revealed = false
        // Brief simulated compute so the loading state is honest and visible.
        try? await Task.sleep(nanoseconds: 250_000_000)
        cycles = NumerologyEngine.personalCycles(for: profile, on: today, config: settings.engineConfig)
        isLoading = false
        triggerReveal()
    }
}

import SwiftUI
import SwiftData

/// What the child will practice in the next round.
enum PracticeMode: Equatable {
    case op(MathOp)
    case mixed

    var opRaw: String {
        switch self {
        case .op(let o): return o.rawValue
        case .mixed: return "mixed"
        }
    }

    var title: String {
        switch self {
        case .op(let o): return o.title
        case .mixed: return "Mixed"
        }
    }
}

struct PlayView: View {
    let selectedProfile: Profile?
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showSwitcher = false
    @State private var mode: PracticeMode = .mixed
    @State private var activeRound: GameConfig?

    var body: some View {
        NavigationStack {
            ScrollView {
                if let profile = selectedProfile {
                    content(profile)
                } else {
                    EmptyStateView(symbol: "person.crop.circle.badge.plus",
                                   title: "Add your first child",
                                   message: "Create a child profile in Settings to start practicing math facts.")
                        .padding(.top, 60)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Digit")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileChip(profile: selectedProfile) { showSwitcher = true }
                }
            }
            .sheet(isPresented: $showSwitcher) {
                ProfileSwitcherSheet()
            }
            .fullScreenCover(item: $activeRound) { config in
                GamePlayerView(config: config)
            }
        }
    }

    @ViewBuilder
    private func content(_ profile: Profile) -> some View {
        let level = Curriculum.level(at: profile.currentLevelIndex)
        let todayStars = todaysStars(profile)
        let streak = ProgressEngine.dayStreak(sessions: profile.sessions)

        VStack(spacing: 18) {
            // Hero greeting card
            Card {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        Text(profile.avatarEmoji).font(.system(size: 44))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hi, \(profile.name)!")
                                .font(Theme.rounded(24, .bold))
                                .foregroundStyle(Theme.ink)
                            Text("\(level.emoji) \(level.title)")
                                .font(Theme.rounded(15, .medium))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                    }
                    HStack(spacing: 10) {
                        StatPill(symbol: "star.fill", value: "\(todayStars)", label: "Today")
                        StatPill(symbol: "flame.fill", value: "\(streak)", label: "Day streak", tint: Theme.bad)
                        StatPill(symbol: "rosette", value: "Lv \(level.id + 1)", label: "Level", tint: Theme.opMul)
                    }
                }
            }
            .padding(.horizontal, 16)

            // Mode chooser
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Choose practice")
                modeChooser(profile)
            }
            .padding(.horizontal, 16)

            // Big play button
            PrimaryButton(title: "Play", systemImage: "play.fill") {
                startRound(profile)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .disabled(!isModeAvailable(profile))
            .opacity(isModeAvailable(profile) ? 1 : 0.5)

            if !isModeAvailable(profile) {
                Text("This mode needs Digit Pro. Try addition or subtraction, or unlock everything in Settings.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            // Recent activity peek
            recentRounds(profile)
                .padding(.horizontal, 16)

            Spacer(minLength: 24)
        }
        .padding(.top, 8)
        .onAppear { ensureValidMode(profile) }
    }

    // MARK: Mode chooser

    private func modeChooser(_ profile: Profile) -> some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)
        return LazyVGrid(columns: cols, spacing: 10) {
            modeCard(.mixed, symbol: "shuffle", locked: false, profile: profile)
            ForEach(MathOp.allCases) { op in
                modeCard(.op(op), symbol: op.sfSymbol,
                         locked: !op.isFree && !settings.isPro, profile: profile)
            }
        }
    }

    private func modeCard(_ candidate: PracticeMode, symbol: String,
                          locked: Bool, profile: Profile) -> some View {
        let selected = mode == candidate
        let tint: Color = {
            if case .op(let o) = candidate { return o.color }
            return Theme.accent
        }()
        return Button {
            mode = candidate
            Haptics.tap(settings.hapticsEnabled)
        } label: {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: symbol)
                        .font(Theme.rounded(20, .bold))
                        .foregroundStyle(tint)
                    Spacer()
                    if locked {
                        Image(systemName: "lock.fill")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    } else if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(Theme.rounded(16))
                            .foregroundStyle(tint)
                    }
                }
                Text(candidate.title)
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(selected ? tint.opacity(0.14) : Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.rMedium, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.rMedium, style: .continuous)
                .stroke(selected ? tint : Theme.hairline, lineWidth: selected ? 2 : 1))
        }
        .accessibilityLabel("\(candidate.title)\(locked ? ", locked, needs Pro" : "")")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: Recent rounds

    @ViewBuilder
    private func recentRounds(_ profile: Profile) -> some View {
        let recent = profile.sessions.sorted { $0.date > $1.date }.prefix(3)
        if recent.isEmpty {
            Card {
                EmptyStateView(symbol: "sparkles",
                               title: "No rounds yet",
                               message: "Tap Play to start your first practice round!")
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Recent rounds")
                ForEach(Array(recent)) { session in
                    Card(padding: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.modeLabel)
                                    .font(Theme.rounded(16, .semibold))
                                    .foregroundStyle(Theme.ink)
                                Text("\(session.correct)/\(session.total) correct • \(relativeDate(session.date))")
                                    .font(Theme.rounded(13))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                            Spacer()
                            StarsView(earned: session.starsEarned, size: 16)
                        }
                    }
                }
            }
        }
    }

    // MARK: Logic

    private func isModeAvailable(_ profile: Profile) -> Bool {
        switch mode {
        case .mixed: return true
        case .op(let o): return o.isFree || settings.isPro
        }
    }

    private func ensureValidMode(_ profile: Profile) {
        if case .op(let o) = mode, !o.isFree, !settings.isPro {
            mode = .mixed
        }
    }

    private func startRound(_ profile: Profile) {
        guard isModeAvailable(profile) else { return }
        let ops = resolvedOps(for: profile)
        let config = GameConfig(profileID: profile.id,
                                modeRaw: mode.opRaw,
                                ops: ops,
                                maxNumber: profile.maxNumber,
                                levelIndex: profile.currentLevelIndex,
                                count: settings.roundLength.rawValue)
        Haptics.tap(settings.hapticsEnabled)
        activeRound = config
    }

    /// Resolve the operations for the chosen mode, intersected with what's allowed.
    private func resolvedOps(for profile: Profile) -> [MathOp] {
        switch mode {
        case .op(let o):
            return [o]
        case .mixed:
            // Mixed uses the profile's enabled ops, but free tier only gets add/sub.
            var ops = Array(profile.enabledOps)
            if !settings.isPro { ops = ops.filter { $0.isFree } }
            if ops.isEmpty { ops = [.add] }
            return ops.sorted { $0.rawValue < $1.rawValue }
        }
    }

    private func todaysStars(_ profile: Profile) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return profile.sessions
            .filter { cal.startOfDay(for: $0.date) == today }
            .reduce(0) { $0 + $1.starsEarned }
    }

    private func relativeDate(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: .now)
    }
}

/// Immutable configuration passed into a game round (Identifiable for fullScreenCover(item:)).
struct GameConfig: Identifiable {
    let id = UUID()
    let profileID: UUID
    let modeRaw: String
    let ops: [MathOp]
    let maxNumber: Int
    let levelIndex: Int
    let count: Int
}

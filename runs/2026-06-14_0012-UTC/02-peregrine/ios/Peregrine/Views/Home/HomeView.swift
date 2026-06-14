import SwiftUI
import SwiftData

/// Home / Dashboard: overall mastery, per-continent bars, streak, the daily
/// challenge card, and the Start-Quiz composer (mode + continent + length).
struct HomeView: View {
    @AppStorage("isPro") private var isPro = false
    @AppStorage("defaultMode") private var defaultModeRaw = QuizMode.flagToCountry.rawValue
    @AppStorage("defaultLength") private var defaultLength = 10

    @Query private var progress: [CountryProgress]
    @Query private var sessions: [QuizSession]

    @State private var selectedMode: QuizMode = .flagToCountry
    @State private var selectedContinent: Continent? = nil
    @State private var path: [QuizConfig] = []
    @State private var showPaywall = false
    @State private var didInit = false

    private var progressByISO: [String: Double] {
        Dictionary(progress.map { ($0.iso2, $0.mastery) }, uniquingKeysWith: { a, _ in a })
    }
    private var overall: Double { Stats.overallMastery(progressByISO: progressByISO) }
    private var continentMastery: [Continent: Double] { Stats.continentMastery(progressByISO: progressByISO) }
    private var streak: Int { Stats.currentStreak(sessionDates: sessions.map { $0.date }) }
    private var quizzesLeft: Int { DailyLimit.remaining(isPro: isPro) }
    private var dailyDoneToday: Bool {
        let key = QuizEngine.dailyKey()
        return sessions.contains { $0.isDaily && QuizEngine.dailyKey(for: $0.date) == key }
    }
    private var hasAnyData: Bool { !sessions.isEmpty || progress.contains { $0.seen > 0 } }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 18) {
                    masteryHeader
                    dailyCard
                    if hasAnyData { continentSection } else { firstRunCard }
                    composer
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Peregrine")
            .navigationDestination(for: QuizConfig.self) { QuizPlayerView(config: $0) }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onAppear(perform: initDefaults)
        }
    }

    private func initDefaults() {
        guard !didInit else { return }
        didInit = true
        selectedMode = QuizMode(rawValue: defaultModeRaw) ?? .flagToCountry
        if !selectedMode.isUnlocked(isPro: isPro) { selectedMode = .flagToCountry }
    }

    // MARK: Sections

    private var masteryHeader: some View {
        GlassCard {
            HStack(spacing: 20) {
                MasteryRing(progress: overall,
                            lineWidth: 12,
                            label: "\(Int(overall * 100))%",
                            sublabel: "mastery")
                    .frame(width: 96, height: 96)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your world")
                        .font(Theme.rounded(20, .bold))
                        .foregroundStyle(Theme.ink)
                    Label("\(streak)-day streak", systemImage: "flame.fill")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(streak > 0 ? Theme.accent : Theme.inkFaint)
                    Text("\(Stats.masteredCount(progressByISO: progressByISO)) of \(CountryData.all.count) countries mastered")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Overall mastery \(Int(overall * 100)) percent, \(streak) day streak")
    }

    private var dailyCard: some View {
        GlassCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(Theme.accentSoft).frame(width: 52, height: 52)
                    Image(systemName: dailyDoneToday ? "checkmark" : "calendar")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Challenge")
                        .font(Theme.rounded(17, .bold))
                        .foregroundStyle(Theme.ink)
                    Text(dailyDoneToday ? "Completed today — come back tomorrow." : "10 mixed questions, the same for everyone.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Button {
                    Haptics.tap()
                    path.append(QuizConfig.daily())
                } label: {
                    Image(systemName: "play.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Circle().fill(dailyDoneToday ? Theme.inkFaint : Theme.accent))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(dailyDoneToday ? "Replay daily challenge" : "Start daily challenge")
            }
        }
    }

    private var firstRunCard: some View {
        GlassCard {
            EmptyStateView(systemImage: "map",
                           title: "Start your atlas",
                           message: "Take your first quiz to begin tracking mastery across the continents.")
        }
    }

    private var continentSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Continents")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)
                ForEach(Continent.displayOrder) { c in
                    MasteryBar(title: c.title,
                               progress: continentMastery[c] ?? 0,
                               tint: c.tint,
                               systemImage: c.systemImage)
                }
            }
        }
    }

    private var composer: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Start a quiz")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)

                pickerRow(title: "Mode") {
                    Menu {
                        ForEach(QuizMode.allCases) { mode in
                            Button {
                                if mode.isUnlocked(isPro: isPro) { selectedMode = mode }
                                else { showPaywall = true }
                            } label: {
                                Label(mode.title + (mode.isUnlocked(isPro: isPro) ? "" : "  (Pro)"),
                                      systemImage: mode.systemImage)
                            }
                        }
                    } label: {
                        menuLabel(selectedMode.title, locked: !selectedMode.isUnlocked(isPro: isPro))
                    }
                }

                pickerRow(title: "Region") {
                    Menu {
                        Button { setContinent(nil) } label: {
                            Label("All continents", systemImage: "globe")
                        }
                        ForEach(Continent.displayOrder) { c in
                            Button {
                                if continentUnlocked(c) { setContinent(c) } else { showPaywall = true }
                            } label: {
                                Label(c.title + (continentUnlocked(c) ? "" : "  (Pro)"), systemImage: c.systemImage)
                            }
                        }
                    } label: {
                        menuLabel(selectedContinent?.title ?? "All continents",
                                  locked: false)
                    }
                }

                pickerRow(title: "Length") {
                    Menu {
                        ForEach([10, 20, 30], id: \.self) { n in
                            Button("\(n) questions") { defaultLength = n }
                        }
                    } label: {
                        menuLabel("\(clampedLength) questions", locked: false)
                    }
                }

                quotaLine
                PrimaryButton(title: "Start Quiz", systemImage: "play.fill",
                              enabled: DailyLimit.canStart(isPro: isPro)) {
                    startQuiz()
                }
            }
        }
    }

    private var clampedLength: Int {
        [10, 20, 30].contains(defaultLength) ? defaultLength : 10
    }

    @ViewBuilder
    private var quotaLine: some View {
        if !isPro {
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.caption2)
                Text(quizzesLeft > 0
                     ? "\(quizzesLeft) of \(DailyLimit.freeQuota) free quizzes left today"
                     : "Daily free quizzes used — unlock Pro for unlimited")
                Spacer()
                Button("Pro") { showPaywall = true }
                    .font(Theme.rounded(13, .bold))
                    .foregroundStyle(Theme.accent)
            }
            .font(Theme.rounded(12, .medium))
            .foregroundStyle(Theme.inkSoft)
        }
    }

    private func pickerRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(title)
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            content()
        }
    }

    private func menuLabel(_ text: String, locked: Bool) -> some View {
        HStack(spacing: 6) {
            Text(text)
                .font(Theme.rounded(15, .semibold))
            if locked { Image(systemName: "lock.fill").font(.caption2) }
            Image(systemName: "chevron.up.chevron.down").font(.caption2)
        }
        .foregroundStyle(Theme.accent)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(Theme.accentSoft))
    }

    private func continentUnlocked(_ c: Continent) -> Bool {
        ProAccess.continentUnlocked(c, isPro: isPro)
    }

    private func setContinent(_ c: Continent?) {
        selectedContinent = c
    }

    private func startQuiz() {
        guard DailyLimit.canStart(isPro: isPro) else { showPaywall = true; return }
        guard selectedMode.isUnlocked(isPro: isPro) else { showPaywall = true; return }
        if let c = selectedContinent, !continentUnlocked(c) { showPaywall = true; return }
        DailyLimit.consume(isPro: isPro)
        defaultModeRaw = selectedMode.rawValue
        Haptics.tap()
        path.append(QuizConfig.standard(mode: selectedMode,
                                        continent: selectedContinent,
                                        length: clampedLength))
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [CountryProgress.self, QuizSession.self], inMemory: true)
}

import SwiftUI
import SwiftData

/// Practice tab: configure & launch an adaptive drill session.
struct PracticeScreen: View {
    @Environment(\.modelContext) private var context
    @AppStorage(Prefs.isPro) private var isPro = false
    @AppStorage(Prefs.frenchEnabled) private var frenchEnabled = false
    @AppStorage(Prefs.answerMode) private var answerModeRaw = AnswerMode.type.rawValue
    @AppStorage(Prefs.accentStrict) private var accentStrict = false
    @AppStorage(Prefs.sessionLength) private var sessionLength = 10
    @AppStorage(Prefs.enabledTenses) private var enabledTensesRaw = Prefs.defaultEnabledTenses

    @Query private var allStats: [ItemStat]

    @State private var language: Language = .spanish
    @State private var showDrill = false
    @State private var paywallReason: PaywallReason?

    private var answerMode: AnswerMode { AnswerMode(rawValue: answerModeRaw) ?? .type }
    private var enabledTenses: Set<String> { Prefs.decodeSet(enabledTensesRaw) }

    private var availableLanguages: [Language] {
        Language.allCases.filter { $0 == .spanish || (frenchEnabled && isPro) }
    }

    private var verbs: [Verb] {
        VerbCatalog.verbs(for: language, proUnlocked: isPro)
    }

    /// Tenses enabled AND available for the current tier.
    private var activeTenses: [Tense] {
        language.tenses.filter {
            enabledTenses.contains($0.rawValue) && ($0.requiresPro ? isPro : true)
        }
    }

    private var canStart: Bool { !verbs.isEmpty && !activeTenses.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        promptPreview
                        languagePicker
                        sessionInfoCard
                        PrimaryButton(title: "Start drill", systemImage: "play.fill", isEnabled: canStart) {
                            showDrill = true
                        }
                        if !canStart {
                            Text("Enable at least one tense in Settings to start.")
                                .font(Theme.rounded(13))
                                .foregroundStyle(Theme.inkSoft)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Practice")
            .toolbar {
                if !isPro {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { paywallReason = .french } label: {
                            Label("Pro", systemImage: "crown.fill")
                                .font(Theme.rounded(13, .semibold))
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showDrill) {
                DrillView(language: language,
                          mode: answerMode,
                          accentStrict: accentStrict,
                          sessionLength: sessionLength,
                          enabledTenses: Set(activeTenses.map { $0.rawValue }),
                          verbs: verbs,
                          existingStats: allStats)
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    private var promptPreview: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 34))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Ready to drill")
                .font(Theme.serif(24, .bold))
                .foregroundStyle(Theme.ink)
            Text("Verbo will focus on the verbs and tenses you struggle with most.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
    }

    private var languagePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Language")
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(Theme.inkSoft)
            HStack(spacing: 10) {
                ForEach(Language.allCases) { lang in
                    let unlocked = availableLanguages.contains(lang)
                    Button {
                        if unlocked {
                            language = lang
                        } else {
                            paywallReason = .french
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(lang.flag)
                            Text(lang.displayName)
                                .font(Theme.rounded(15, .semibold))
                            if !unlocked {
                                Image(systemName: "lock.fill").font(.system(size: 11))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(language == lang ? Theme.accentSoft : Theme.surfaceAlt)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(language == lang ? Theme.accent : .clear, lineWidth: 1.5)
                        )
                        .foregroundStyle(unlocked ? Theme.ink : Theme.inkFaint)
                    }
                }
            }
        }
    }

    private var sessionInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            infoRow("Questions", "\(sessionLength)", "number.circle")
            Divider().background(Theme.hairline)
            infoRow("Answer mode", answerMode.displayName, "keyboard")
            Divider().background(Theme.hairline)
            infoRow("Accents", accentStrict ? "Strict" : "Lenient", "a.circle")
            Divider().background(Theme.hairline)
            infoRow("Tenses", activeTenses.isEmpty ? "None enabled" : activeTenses.map { $0.displayName }.joined(separator: ", "), "clock")
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
    }

    private func infoRow(_ title: String, _ value: String, _ symbol: String) -> some View {
        HStack(alignment: .top) {
            Label(title, systemImage: symbol)
                .font(Theme.rounded(14, .medium))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value)
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }
}

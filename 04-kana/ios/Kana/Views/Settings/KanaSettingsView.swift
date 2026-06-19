import SwiftUI

struct KanaSettingsView: View {
    @AppStorage(KanaSettings.studyCardType) private var studyCardTypeRaw: String = ""
    @AppStorage(KanaSettings.dailyGoal) private var dailyGoal: Int = 20
    @AppStorage(KanaSettings.showRomaji) private var showRomaji: Bool = false
    @AppStorage(KanaSettings.hapticFeedback) private var hapticFeedback: Bool = true
    @AppStorage(KanaSettings.onboardingDone) private var onboardingDone: Bool = true
    @State private var showOnboarding: Bool = false
    @State private var showResetConfirm: Bool = false

    private var selectedCardType: Binding<String> {
        Binding(
            get: { studyCardTypeRaw },
            set: { studyCardTypeRaw = $0 }
        )
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        NavigationStack {
            Form {
                // Study Section
                Section {
                    Picker("Card Type", selection: selectedCardType) {
                        Text("All").tag("")
                        ForEach(CardType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: KanaTheme.cardTypeIcon(type))
                                    .foregroundStyle(KanaTheme.cardTypeColor(type))
                                Text(type.displayName)
                            }
                            .tag(type.rawValue)
                        }
                    }
                    .pickerStyle(.menu)

                    Stepper(value: $dailyGoal, in: 5...50, step: 5) {
                        HStack {
                            Text("Daily Goal")
                            Spacer()
                            Text("\(dailyGoal) cards")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Study")
                } footer: {
                    Text("Choose which card type to focus on during study sessions. Daily goal sets your target review count per day.")
                }

                // Display Section
                Section {
                    Toggle(isOn: $showRomaji) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Show Romaji on Front")
                                Text("Display romanization before flipping")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "textformat.abc")
                                .foregroundStyle(KanaTheme.crimsonRed)
                        }
                    }
                    .tint(KanaTheme.crimsonRed)
                } header: {
                    Text("Display")
                }

                // Feedback Section
                Section {
                    Toggle(isOn: $hapticFeedback) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Haptic Feedback")
                                Text("Vibrate on correct and incorrect answers")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "hand.tap.fill")
                                .foregroundStyle(KanaTheme.crimsonRed)
                        }
                    }
                    .tint(KanaTheme.crimsonRed)
                } header: {
                    Text("Feedback")
                }

                // Onboarding Section
                Section {
                    Button {
                        showOnboarding = true
                    } label: {
                        Label("Replay Onboarding", systemImage: "play.circle.fill")
                            .foregroundStyle(KanaTheme.crimsonRed)
                    }
                } header: {
                    Text("Help")
                } footer: {
                    Text("Watch the intro again to refresh your memory on how Kana works.")
                }

                // About Section
                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle.fill")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(appVersion) (\(buildNumber))")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Characters", systemImage: "character.book.closed.fill")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("112 total")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Algorithm", systemImage: "brain")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("SM-2 SRS")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About Kana")
                } footer: {
                    Text("Kana uses the SM-2 spaced repetition algorithm to schedule reviews at the optimal time for long-term retention. 46 hiragana, 46 katakana, and 20 N5 kanji are included.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(isPresented: $showOnboarding) {
                KanaOnboardingView()
            }
        }
    }
}

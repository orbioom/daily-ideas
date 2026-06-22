import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsArray: [ScrawlSettings]
    @Environment(\.modelContext) private var modelContext

    private var settings: ScrawlSettings? { settingsArray.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let settings {
                        gameplaySection(settings: settings)
                        feedbackSection(settings: settings)
                        aboutSection(settings: settings)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(ScrawlTheme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func gameplaySection(settings: ScrawlSettings) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader2(title: "Gameplay", icon: "gamecontroller.fill")

            VStack(spacing: 0) {
                // Timer
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(ScrawlTheme.skyBlue)
                            .frame(width: 24)
                        Text("Default Timer")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(ScrawlTheme.primaryText)
                    }

                    Picker("Timer", selection: Binding(
                        get: { settings.timerSeconds },
                        set: { settings.timerSeconds = $0 }
                    )) {
                        Text("30s").tag(30)
                        Text("60s").tag(60)
                        Text("90s").tag(90)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Default timer duration")
                }
                .padding(16)

                Divider().padding(.horizontal, 16)

                // Rounds
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(ScrawlTheme.coral)
                        .frame(width: 24)
                    Text("Default Rounds")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(ScrawlTheme.primaryText)

                    Spacer()

                    HStack(spacing: 14) {
                        Button {
                            if settings.roundCount > 1 {
                                settings.roundCount -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(settings.roundCount > 1 ? ScrawlTheme.skyBlue : ScrawlTheme.warmGray)
                        }
                        .disabled(settings.roundCount <= 1)
                        .accessibilityLabel("Decrease rounds")

                        Text("\(settings.roundCount)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(ScrawlTheme.primaryText)
                            .frame(minWidth: 28)

                        Button {
                            if settings.roundCount < 10 {
                                settings.roundCount += 1
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(settings.roundCount < 10 ? ScrawlTheme.skyBlue : ScrawlTheme.warmGray)
                        }
                        .disabled(settings.roundCount >= 10)
                        .accessibilityLabel("Increase rounds")
                    }
                }
                .padding(16)
            }
            .scrawlCard()
        }
    }

    private func feedbackSection(settings: ScrawlSettings) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader2(title: "Feedback", icon: "hand.thumbsup.fill")

            VStack(spacing: 0) {
                // Haptics
                HStack {
                    Image(systemName: "iphone.radiowaves.left.and.right")
                        .foregroundStyle(ScrawlTheme.successGreen)
                        .frame(width: 24)

                    Text("Haptic Feedback")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(ScrawlTheme.primaryText)

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { settings.hapticsEnabled },
                        set: { settings.hapticsEnabled = $0 }
                    ))
                    .tint(ScrawlTheme.skyBlue)
                    .accessibilityLabel("Haptic feedback")
                }
                .padding(16)
            }
            .scrawlCard()
        }
    }

    private func aboutSection(settings: ScrawlSettings) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader2(title: "About", icon: "info.circle.fill")

            VStack(spacing: 0) {
                SettingsRow(icon: "star.fill", color: ScrawlTheme.warningOrange, title: "Rate Scrawl") {
                    // Rate app link
                }

                Divider().padding(.horizontal, 16)

                SettingsRow(icon: "envelope.fill", color: ScrawlTheme.skyBlue, title: "Contact Support") {
                    // Email support
                }

                Divider().padding(.horizontal, 16)

                HStack {
                    Image(systemName: "app.badge.fill")
                        .foregroundStyle(ScrawlTheme.coral)
                        .frame(width: 24)
                    Text("Version")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(ScrawlTheme.primaryText)
                    Spacer()
                    Text("1.0.0")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(ScrawlTheme.secondaryText)
                }
                .padding(16)

                Divider().padding(.horizontal, 16)

                Button {
                    settings.hasCompletedOnboarding = false
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundStyle(ScrawlTheme.secondaryText)
                            .frame(width: 24)
                        Text("Replay Onboarding")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(ScrawlTheme.secondaryText)
                        Spacer()
                    }
                    .padding(16)
                }
                .accessibilityLabel("Replay onboarding tutorial")
            }
            .scrawlCard()
        }
    }
}

struct SectionHeader2: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(ScrawlTheme.skyBlue)
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(ScrawlTheme.primaryText)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let color: Color
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(ScrawlTheme.primaryText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ScrawlTheme.secondaryText)
            }
            .padding(16)
        }
        .accessibilityLabel(title)
    }
}

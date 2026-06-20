import SwiftUI

struct HuntSettingsView: View {
    @AppStorage("hunt_timer_duration") private var timerDuration = 120
    @AppStorage("hunt_min_word_length") private var minWordLength = 3
    @AppStorage("hunt_haptics_enabled") private var hapticsEnabled = true
    @AppStorage("hunt_show_hints") private var showHints = false
    @AppStorage("hunt_pro_unlocked") private var proUnlocked = false

    var body: some View {
        ZStack {
            HuntTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Text("Settings")
                        .font(.largeTitle.bold())
                        .foregroundStyle(HuntTheme.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // Timer duration
                    settingsSection(title: "Timer Duration") {
                        Picker("Timer", selection: $timerDuration) {
                            Text("90 sec").tag(90)
                            Text("2 min").tag(120)
                            Text("3 min").tag(180)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .tint(HuntTheme.accent)
                    }

                    // Min word length
                    settingsSection(title: "Minimum Word Length") {
                        Picker("Min Length", selection: $minWordLength) {
                            Text("3 letters").tag(3)
                            Text("4 letters").tag(4)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .tint(HuntTheme.accent)
                    }

                    // Toggles
                    settingsSection(title: "Feedback") {
                        VStack(spacing: 0) {
                            Toggle(isOn: $hapticsEnabled) {
                                Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
                                    .foregroundStyle(HuntTheme.primaryText)
                            }
                            .tint(HuntTheme.accent)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                            Divider()
                                .background(HuntTheme.tileBackground)

                            Toggle(isOn: $showHints) {
                                Label("Show Word Hints", systemImage: "lightbulb.fill")
                                    .foregroundStyle(HuntTheme.primaryText)
                            }
                            .tint(HuntTheme.accent)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }

                    // Pro unlock
                    proSection

                    // About
                    settingsSection(title: "About") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Version")
                                    .foregroundStyle(HuntTheme.secondaryText)
                                Spacer()
                                Text("1.0.0")
                                    .foregroundStyle(HuntTheme.primaryText)
                            }
                            Divider().background(HuntTheme.tileBackground)
                            HStack {
                                Text("Dictionary")
                                    .foregroundStyle(HuntTheme.secondaryText)
                                Spacer()
                                Text("\(WordList.words.count) words")
                                    .foregroundStyle(HuntTheme.primaryText)
                            }
                        }
                        .padding(16)
                    }
                }
                .padding(.bottom, 32)
            }
        }
    }

    private var proSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pro")
                .font(.headline)
                .foregroundStyle(HuntTheme.secondaryText)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                if proUnlocked {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.yellow)
                        Text("Hunt Pro — Unlocked")
                            .fontWeight(.semibold)
                            .foregroundStyle(HuntTheme.primaryText)
                        Spacer()
                    }
                    .padding(16)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hunt Pro")
                                    .font(.headline)
                                    .foregroundStyle(HuntTheme.primaryText)
                                Text("One-time purchase")
                                    .font(.caption)
                                    .foregroundStyle(HuntTheme.secondaryText)
                            }
                            Spacer()
                            Text("$2.99")
                                .font(.title3.bold())
                                .foregroundStyle(HuntTheme.accent)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            ProFeatureRow(text: "3-minute extended mode")
                            ProFeatureRow(text: "4-letter minimum mode")
                            ProFeatureRow(text: "Board themes")
                            ProFeatureRow(text: "Unlimited daily history")
                        }

                        Button {
                            // StoreKit purchase would go here
                            proUnlocked = true
                        } label: {
                            Text("Unlock Hunt Pro")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(HuntTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(16)
                }
            }
            .background(HuntTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private func settingsSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(HuntTheme.secondaryText)
                .padding(.horizontal, 20)

            content()
                .background(HuntTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
        }
    }
}

private struct ProFeatureRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.caption.bold())
                .foregroundStyle(HuntTheme.accent)
            Text(text)
                .font(.callout)
                .foregroundStyle(HuntTheme.primaryText)
        }
    }
}

#Preview {
    HuntSettingsView()
}

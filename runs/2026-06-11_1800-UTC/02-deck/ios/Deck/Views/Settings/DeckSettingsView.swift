import SwiftUI

struct DeckSettingsView: View {
    @AppStorage("dailyReviewLimit") private var dailyLimit = 20
    @AppStorage("showDueCountBadge") private var showDueBadge = true
    @AppStorage("hapticsEnabled") private var haptics = true
    @AppStorage("autoFlipDelay") private var autoFlip = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Study") {
                    Stepper("Daily review limit: \(dailyLimit)", value: $dailyLimit, in: 5...200, step: 5)
                        .accessibilityLabel("Daily review limit: \(dailyLimit) cards")
                    Toggle("Auto-flip cards", isOn: $autoFlip)
                        .tint(DeckTheme.accent)
                        .accessibilityLabel("Automatically flip cards after showing")
                }

                Section("Display") {
                    Toggle("Show due count badges", isOn: $showDueBadge)
                        .tint(DeckTheme.accent)
                        .accessibilityLabel("Show number of due cards on deck list")
                }

                Section("Feedback") {
                    Toggle("Haptics", isOn: $haptics)
                        .tint(DeckTheme.accent)
                        .accessibilityLabel("Enable haptic feedback during study")
                }

                Section("SM-2 Algorithm") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Deck uses the SM-2 spaced-repetition algorithm. Cards rated 'Again' reset to 1 day. 'Easy' cards grow faster intervals. The ease factor adjusts per card based on your performance.")
                            .font(.caption)
                            .foregroundStyle(DeckTheme.subtle)
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version"); Spacer()
                        Text("1.0").foregroundStyle(DeckTheme.subtle)
                    }
                    HStack {
                        Text("Data"); Spacer()
                        Text("On-device only").font(.caption).foregroundStyle(DeckTheme.subtle)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(DeckTheme.bg)
            .navigationTitle("Settings")
        }
    }
}

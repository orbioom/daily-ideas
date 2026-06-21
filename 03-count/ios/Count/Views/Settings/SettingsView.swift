import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsArr: [CountSettings]
    @Environment(\.modelContext) private var modelContext
    @State private var showProSheet: Bool = false

    private var settings: CountSettings? { settingsArr.first }

    private let deckOptions = [1, 2, 4, 6, 8]

    var body: some View {
        NavigationStack {
            Group {
                if let settings = settings {
                    Form {
                        trainingSection(settings: settings)
                        feedbackSection(settings: settings)
                        deckSection(settings: settings)
                        proSection(settings: settings)
                        aboutSection
                    }
                } else {
                    ProgressView("Loading settings...")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showProSheet) {
                if let settings = settings {
                    ProUpgradeSheet(settings: settings)
                }
            }
        }
    }

    @ViewBuilder
    private func trainingSection(settings: CountSettings) -> some View {
        Section {
            Picker("Difficulty", selection: Binding(
                get: { settings.difficulty },
                set: { settings.difficulty = $0; saveSettings() }
            )) {
                Text("Beginner").tag("Beginner")
                Text("Standard").tag("Standard")
                Text("Advanced").tag("Advanced")
            }
            .pickerStyle(.segmented)
            .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(difficultyDescription(settings.difficulty))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Training Mode")
        }
    }

    @ViewBuilder
    private func feedbackSection(settings: CountSettings) -> some View {
        Section {
            Toggle(isOn: Binding(
                get: { settings.showHints },
                set: { settings.showHints = $0; saveSettings() }
            )) {
                Label("Show Hints", systemImage: "lightbulb.fill")
            }
            .tint(CountTheme.accent)

            Toggle(isOn: Binding(
                get: { settings.hapticEnabled },
                set: { settings.hapticEnabled = $0; saveSettings() }
            )) {
                Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
            }
            .tint(CountTheme.accent)

            Toggle(isOn: Binding(
                get: { settings.showCorrectOnWrong },
                set: { settings.showCorrectOnWrong = $0; saveSettings() }
            )) {
                Label("Show Correct Answer on Wrong", systemImage: "checkmark.bubble.fill")
            }
            .tint(CountTheme.accent)
        } header: {
            Text("Feedback")
        } footer: {
            Text("Hints briefly highlight the correct answer before showing results. Requires Show Correct on Wrong to be enabled.")
                .font(.caption)
        }
    }

    @ViewBuilder
    private func deckSection(settings: CountSettings) -> some View {
        Section {
            Picker("Number of Decks", selection: Binding(
                get: { settings.decks },
                set: { settings.decks = $0; saveSettings() }
            )) {
                ForEach(deckOptions, id: \.self) { n in
                    Text(n == 1 ? "1 Deck (Single)" : "\(n) Decks").tag(n)
                }
            }
        } header: {
            Text("Shoe Configuration")
        } footer: {
            Text("Most casinos use 6 or 8 decks. Strategy is the same for 4–8 decks.")
                .font(.caption)
        }
    }

    @ViewBuilder
    private func proSection(settings: CountSettings) -> some View {
        Section {
            if settings.isPro {
                HStack {
                    Label("Count Pro", systemImage: "crown.fill")
                        .foregroundStyle(.yellow)
                    Spacer()
                    Text("Active")
                        .font(.caption.bold())
                        .foregroundStyle(CountTheme.correctGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(CountTheme.correctGreen.opacity(0.15))
                        .clipShape(Capsule())
                }
            } else {
                Button {
                    showProSheet = true
                } label: {
                    HStack {
                        Label("Upgrade to Pro", systemImage: "crown.fill")
                            .foregroundStyle(.yellow)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)

                Text("Unlock unlimited history, advanced stats, and custom strategy tables.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Pro Features")
        }
    }

    @ViewBuilder
    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Strategy")
                Spacer()
                Text("Standard Multi-Deck")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("About Count")
        } footer: {
            Text("Count uses standard basic strategy for 4-8 deck games with dealer standing on soft 17. Always play responsibly.")
                .font(.caption)
        }
    }

    private func saveSettings() {
        try? modelContext.save()
    }

    private func difficultyDescription(_ difficulty: String) -> String {
        switch difficulty {
        case "Beginner":
            return "Focuses on hard totals only. Perfect for learning the fundamentals."
        case "Advanced":
            return "Includes surrender decisions and edge cases. For experienced players."
        default:
            return "Full basic strategy including pairs and soft hands."
        }
    }
}

struct ProUpgradeSheet: View {
    let settings: CountSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.yellow)
                            .padding(.top, 24)

                        Text("Count Pro")
                            .font(.system(size: 30, weight: .bold, design: .rounded))

                        Text("Everything you need to master basic strategy")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        ProFeatureRow(icon: "clock.fill", title: "Unlimited History", description: "Access your full training history with no limits.")
                        ProFeatureRow(icon: "chart.xyaxis.line", title: "Advanced Stats", description: "Deep-dive charts showing performance trends over time.")
                        ProFeatureRow(icon: "table.fill", title: "Strategy Reference", description: "Full basic strategy chart always at your fingertips.")
                        ProFeatureRow(icon: "bell.badge.fill", title: "Daily Reminders", description: "Custom notifications to keep your practice streak going.")
                    }
                    .padding(.horizontal)

                    VStack(spacing: 12) {
                        Button {
                            settings.isPro = true
                            try? modelContext.save()
                            dismiss()
                        } label: {
                            Text("Unlock Pro — $4.99")
                                .font(.headline.bold())
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(.yellow)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button {
                            settings.isPro = true
                            try? modelContext.save()
                            dismiss()
                        } label: {
                            Text("Restore Purchase")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Text("One-time purchase. No subscription.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct ProFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(.yellow)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

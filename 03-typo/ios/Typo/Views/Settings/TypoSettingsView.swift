import SwiftUI
import SwiftData

struct TypoSettingsView: View {
    @Query private var settingsList: [TypoSettings]
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TypoResult.date) private var results: [TypoResult]

    private var settings: TypoSettings {
        if let s = settingsList.first { return s }
        let s = TypoSettings(); modelContext.insert(s); return s
    }

    var body: some View {
        ZStack {
            TypoTheme.background.ignoresSafeArea()
            List {
                displaySection
                inputSection
                statsSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(TypoTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    var displaySection: some View {
        Section {
            Toggle("Show Live WPM", isOn: Binding(
                get: { settings.showLiveWpm },
                set: { settings.showLiveWpm = $0 }
            ))
            .foregroundStyle(TypoTheme.textPrimary)
            .tint(TypoTheme.accent)
        } header: {
            Text("Display").foregroundStyle(TypoTheme.textSecondary)
        }
        .listRowBackground(TypoTheme.surface)
    }

    var inputSection: some View {
        Section {
            Toggle("Haptic Feedback", isOn: Binding(
                get: { settings.hapticsEnabled },
                set: { settings.hapticsEnabled = $0 }
            ))
            .foregroundStyle(TypoTheme.textPrimary)
            .tint(TypoTheme.accent)

            Toggle("Sound Effects", isOn: Binding(
                get: { settings.soundEnabled },
                set: { settings.soundEnabled = $0 }
            ))
            .foregroundStyle(TypoTheme.textPrimary)
            .tint(TypoTheme.accent)
        } header: {
            Text("Input").foregroundStyle(TypoTheme.textSecondary)
        }
        .listRowBackground(TypoTheme.surface)
    }

    var statsSection: some View {
        let best = results.map { $0.wpm }.max() ?? 0
        let total = results.count
        return Section {
            statRow("Tests Completed", "\(total)")
            statRow("Best WPM", "\(Int(best))")
            Button(role: .destructive) {
                results.forEach { modelContext.delete($0) }
            } label: {
                Text("Clear All History")
                    .foregroundStyle(TypoTheme.wrongRed)
            }
        } header: {
            Text("Statistics").foregroundStyle(TypoTheme.textSecondary)
        }
        .listRowBackground(TypoTheme.surface)
    }

    func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(TypoTheme.textSecondary)
            Spacer()
            Text(value).foregroundStyle(TypoTheme.textPrimary)
        }
    }

    var aboutSection: some View {
        Section {
            statRow("Version", "1.0")
            statRow("Word Bank", "200+ words")
            statRow("Modes", "Words, Sentences, Code, Numbers")
        } header: {
            Text("About Typo").foregroundStyle(TypoTheme.textSecondary)
        }
        .listRowBackground(TypoTheme.surface)
    }
}

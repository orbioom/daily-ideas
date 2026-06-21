import SwiftUI
import SwiftData

struct SeekSettingsView: View {
    @Query private var settingsList: [SeekSettings]
    @Environment(\.modelContext) private var modelContext
    @Query private var records: [PuzzleRecord]

    private var settings: SeekSettings {
        if let s = settingsList.first { return s }
        let s = SeekSettings(); modelContext.insert(s); return s
    }

    var body: some View {
        ZStack {
            SeekTheme.background.ignoresSafeArea()
            List {
                gameSection
                audioSection
                statsSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(SeekTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    var gameSection: some View {
        Section {
            Picker("Default Difficulty", selection: Binding(
                get: { settings.preferredDifficulty },
                set: { settings.preferredDifficulty = $0 }
            )) {
                ForEach(PuzzleDifficulty.allCases, id: \.self) { d in
                    Text(d.rawValue).tag(d.rawValue)
                }
            }
            .foregroundStyle(SeekTheme.textPrimary)

            Toggle("Show Timer", isOn: Binding(
                get: { settings.showTimer },
                set: { settings.showTimer = $0 }
            ))
            .foregroundStyle(SeekTheme.textPrimary)
            .tint(SeekTheme.accent)
        } header: {
            Text("Game").foregroundStyle(SeekTheme.textSecondary)
        }
        .listRowBackground(SeekTheme.surface)
    }

    var audioSection: some View {
        Section {
            Toggle("Sound Effects", isOn: Binding(
                get: { settings.soundEnabled },
                set: { settings.soundEnabled = $0 }
            ))
            .foregroundStyle(SeekTheme.textPrimary)
            .tint(SeekTheme.accent)

            Toggle("Haptic Feedback", isOn: Binding(
                get: { settings.hapticsEnabled },
                set: { settings.hapticsEnabled = $0 }
            ))
            .foregroundStyle(SeekTheme.textPrimary)
            .tint(SeekTheme.accent)
        } header: {
            Text("Audio & Feel").foregroundStyle(SeekTheme.textSecondary)
        }
        .listRowBackground(SeekTheme.surface)
    }

    var statsSection: some View {
        let completed = records.filter { $0.completed }
        return Section {
            statRow("Puzzles Played", "\(records.count)")
            statRow("Completed", "\(completed.count)")
            Button(role: .destructive) {
                records.forEach { modelContext.delete($0) }
            } label: {
                Text("Clear All Stats").foregroundStyle(.red)
            }
        } header: {
            Text("Statistics").foregroundStyle(SeekTheme.textSecondary)
        }
        .listRowBackground(SeekTheme.surface)
    }

    func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(SeekTheme.textSecondary)
            Spacer()
            Text(value).foregroundStyle(SeekTheme.textPrimary)
        }
    }

    var aboutSection: some View {
        Section {
            statRow("Version", "1.0")
            statRow("Ads", "Zero")
            statRow("Categories", "\(WordCategory.all.count)")
            statRow("Difficulty Levels", "3")
            statRow("Word Directions", "8 (including diagonals)")
        } header: {
            Text("About Seek").foregroundStyle(SeekTheme.textSecondary)
        }
        .listRowBackground(SeekTheme.surface)
    }
}

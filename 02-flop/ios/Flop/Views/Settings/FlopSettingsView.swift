import SwiftUI
import SwiftData

struct FlopSettingsView: View {
    @Query private var settingsList: [FlopSettings]
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FlopQuizRecord.date, order: .reverse) private var records: [FlopQuizRecord]

    private var settings: FlopSettings {
        if let s = settingsList.first { return s }
        let s = FlopSettings(); modelContext.insert(s); return s
    }

    var body: some View {
        ZStack {
            FlopTheme.background.ignoresSafeArea()
            List {
                quizSection
                appearanceSection
                statsSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(FlopTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    var quizSection: some View {
        Section {
            Toggle("Show Explanations", isOn: Binding(
                get: { settings.showExplanations },
                set: { settings.showExplanations = $0 }
            ))
            .foregroundStyle(FlopTheme.textPrimary)
            .tint(FlopTheme.accent)

            Toggle("Haptic Feedback", isOn: Binding(
                get: { settings.hapticsEnabled },
                set: { settings.hapticsEnabled = $0 }
            ))
            .foregroundStyle(FlopTheme.textPrimary)
            .tint(FlopTheme.accent)

            HStack {
                Text("Daily Goal")
                    .foregroundStyle(FlopTheme.textPrimary)
                Spacer()
                Stepper("\(settings.dailyGoal) hands", value: Binding(
                    get: { settings.dailyGoal },
                    set: { settings.dailyGoal = $0 }
                ), in: 5...200, step: 5)
                .foregroundStyle(FlopTheme.textSecondary)
            }

            Picker("Default Position", selection: Binding(
                get: { settings.preferredPosition },
                set: { settings.preferredPosition = $0 }
            )) {
                ForEach(PokerPosition.allCases, id: \.self) { pos in
                    Text(pos.rawValue).tag(pos.rawValue)
                }
            }
            .foregroundStyle(FlopTheme.textPrimary)
        } header: {
            Text("Quiz").foregroundStyle(FlopTheme.textSecondary)
        }
        .listRowBackground(FlopTheme.felt)
    }

    var appearanceSection: some View {
        Section {
            HStack {
                Text("Theme")
                    .foregroundStyle(FlopTheme.textPrimary)
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(FlopTheme.background).frame(width: 16, height: 16)
                        .overlay(Circle().stroke(FlopTheme.accent, lineWidth: 1.5))
                    Text("Felt Green")
                        .font(.system(size: 13))
                        .foregroundStyle(FlopTheme.textSecondary)
                }
            }
        } header: {
            Text("Appearance").foregroundStyle(FlopTheme.textSecondary)
        }
        .listRowBackground(FlopTheme.felt)
    }

    var statsSection: some View {
        let correct = records.filter { $0.wasCorrect }.count
        let total = records.count
        return Section {
            statRow("Total Quiz Hands", "\(total)")
            statRow("Correct Answers", "\(correct)")
            statRow("Overall Accuracy", total > 0 ? "\(Int(Double(correct)/Double(total)*100))%" : "—")
            Button(role: .destructive) {
                resetStats()
            } label: {
                Text("Reset Quiz Stats")
                    .foregroundStyle(FlopTheme.wrongRed)
            }
        } header: {
            Text("Statistics").foregroundStyle(FlopTheme.textSecondary)
        }
        .listRowBackground(FlopTheme.felt)
    }

    func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(FlopTheme.textSecondary)
            Spacer()
            Text(value).foregroundStyle(FlopTheme.textPrimary)
        }
    }

    var aboutSection: some View {
        Section {
            HStack {
                Text("Version").foregroundStyle(FlopTheme.textSecondary)
                Spacer()
                Text("1.0").foregroundStyle(FlopTheme.textPrimary)
            }
            HStack {
                Text("Strategy").foregroundStyle(FlopTheme.textSecondary)
                Spacer()
                Text("GTO 6-max NL").foregroundStyle(FlopTheme.textPrimary)
            }
            HStack {
                Text("Positions").foregroundStyle(FlopTheme.textSecondary)
                Spacer()
                Text("UTG / MP / CO / BTN / SB / BB").foregroundStyle(FlopTheme.textPrimary)
            }
        } header: {
            Text("About Flop").foregroundStyle(FlopTheme.textSecondary)
        }
        .listRowBackground(FlopTheme.felt)
    }

    func resetStats() {
        records.forEach { modelContext.delete($0) }
    }
}

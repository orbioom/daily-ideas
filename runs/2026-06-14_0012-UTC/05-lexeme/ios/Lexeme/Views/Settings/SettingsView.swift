import SwiftUI
import SwiftData

/// Persisted preferences plus Pro / restore / reset / about.
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("isPro") private var isPro = false
    @AppStorage("dailyReviewGoal") private var dailyGoal = 20
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 8
    @AppStorage("preferredTier") private var preferredTier = WordTier.everyday.rawValue
    @AppStorage("typedFillBlank") private var typedFillBlank = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    @State private var showPaywall = false
    @State private var showResetConfirm = false
    @State private var didReset = false

    private var store: ProgressStore { ProgressStore(context: context) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Form {
                    studySection
                    remindersSection
                    quizSection
                    proSection
                    dataSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Study

    private var studySection: some View {
        Section {
            Stepper(value: $dailyGoal, in: 5...100, step: 5) {
                HStack {
                    Label("Daily review goal", systemImage: "target")
                    Spacer()
                    Text("\(dailyGoal)").foregroundStyle(Theme.inkSoft).monospacedDigit()
                }
            }
            Picker(selection: $preferredTier) {
                ForEach(WordTier.allCases) { t in Text(t.label).tag(t.rawValue) }
            } label: {
                Label("Preferred tier focus", systemImage: "books.vertical")
            }
        } header: {
            Text("Study")
        } footer: {
            Text("Your daily goal sizes each review session. Tier focus highlights where you want to grow.")
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: - Reminders

    private var remindersSection: some View {
        Section {
            Toggle(isOn: $reminderEnabled) {
                Label("Daily word reminder", systemImage: "bell")
            }
            if reminderEnabled {
                Picker(selection: $reminderHour) {
                    ForEach(0..<24, id: \.self) { h in
                        Text(hourLabel(h)).tag(h)
                    }
                } label: {
                    Label("Reminder time", systemImage: "clock")
                }
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text("Saves your preferred reminder time. This demo build stores the preference only; production wires a local notification.")
        }
        .listRowBackground(Theme.surface)
    }

    private func hourLabel(_ h: Int) -> String {
        var c = DateComponents(); c.hour = h; c.minute = 0
        let date = Calendar.current.date(from: c) ?? Date()
        return date.formatted(.dateTime.hour().minute())
    }

    // MARK: - Quiz

    private var quizSection: some View {
        Section {
            Toggle(isOn: $typedFillBlank) {
                Label("Type fill-in-the-blank", systemImage: "keyboard")
            }
            Toggle(isOn: $hapticsEnabled) {
                Label("Haptic feedback", systemImage: "hand.tap")
            }
        } header: {
            Text("Quiz & feedback")
        } footer: {
            Text("When typing is on, fill-in-the-blank asks you to type the word (case and accents are forgiven) instead of choosing.")
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: - Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Lexeme Pro", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.good)
                    Spacer()
                    Text("Active").foregroundStyle(Theme.inkSoft)
                }
            } else {
                Button { showPaywall = true } label: {
                    Label("Unlock Lexeme Pro", systemImage: "sparkles")
                        .foregroundStyle(Theme.accent)
                }
            }
            Button {
                // Demo restore: re-applies the local unlock flag.
                isPro = true
                Haptics.success()
            } label: {
                Label("Restore purchase", systemImage: "arrow.clockwise")
            }
        } header: {
            Text("Membership")
        }
        .listRowBackground(Theme.surface)
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    // MARK: - Data

    private var dataSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset all progress", systemImage: "trash")
            }
            if didReset {
                Label("Progress cleared", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Theme.good)
                    .font(Theme.rounded(13))
            }
        } header: {
            Text("Data")
        } footer: {
            Text("Removes every word's mastery, your favorites, and your study history. Word entries themselves are never deleted.")
        }
        .listRowBackground(Theme.surface)
        .confirmationDialog("Reset all progress?",
                            isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Reset everything", role: .destructive) {
                store.resetAll()
                Haptics.error()
                withAnimation { didReset = true }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            NavigationLink { AboutView() } label: {
                Label("About Lexeme", systemImage: "info.circle")
            }
            HStack {
                Label("Version", systemImage: "number")
                Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
            HStack {
                Label("Words in bank", systemImage: "text.book.closed")
                Spacer()
                Text("\(WordBank.all.count)").foregroundStyle(Theme.inkSoft)
            }
        } header: {
            Text("About")
        }
        .listRowBackground(Theme.surface)
    }
}

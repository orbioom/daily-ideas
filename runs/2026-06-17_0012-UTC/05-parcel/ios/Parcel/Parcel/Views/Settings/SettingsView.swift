import SwiftUI
import SwiftData

/// App settings — at least three persisted, functional preferences plus Pro and About.
struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context
    @Environment(AppPreferences.self) private var prefs

    @State private var showPaywall = false
    @State private var confirmReset = false
    @State private var resetDone = false

    var body: some View {
        @Bindable var prefs = prefs
        return NavigationStack {
            Form {
                // MARK: Pro
                Section {
                    if prefs.isPro {
                        Label("Parcel Pro unlocked", systemImage: "crown.fill")
                            .foregroundStyle(Theme.gold)
                    } else {
                        Button { showPaywall = true } label: {
                            HStack {
                                Label("Unlock Parcel Pro", systemImage: "crown.fill")
                                Spacer()
                                Text("$6.99").foregroundStyle(Theme.textSecondary(scheme))
                            }
                        }
                        .tint(Theme.accent)
                    }
                }

                // MARK: Exam preferences
                Section("Exam") {
                    Stepper(value: $prefs.quickLength, in: 5...20) {
                        settingRow("Quick quiz length", "\(prefs.quickLength) questions")
                    }
                    Stepper(value: $prefs.mockLength, in: 20...100, step: 5) {
                        settingRow("Mock exam length", "\(prefs.mockLength) questions")
                    }
                    Stepper(value: $prefs.passPercent, in: 60...90) {
                        settingRow("Pass threshold", "\(prefs.passPercent)%")
                    }
                    Toggle("Shuffle answer order", isOn: $prefs.shuffleOptions)
                }

                // MARK: Study
                Section("Study") {
                    Toggle(isOn: readAloudBinding) {
                        HStack(spacing: 6) {
                            Text("Read questions aloud")
                            if !prefs.isPro { ProBadge() }
                        }
                    }
                    Toggle("Haptic feedback", isOn: $prefs.hapticsEnabled)
                }

                // MARK: Data
                Section("Data") {
                    Button(role: .destructive) { confirmReset = true } label: {
                        Label("Reset all progress", systemImage: "trash")
                    }
                }

                // MARK: About
                Section("About") {
                    NavigationLink { DisclaimerView() } label: {
                        Label("Disclaimer", systemImage: "exclamationmark.shield")
                    }
                    NavigationLink { AboutView() } label: {
                        Label("About Parcel", systemImage: "info.circle")
                    }
                    HStack {
                        Text("Questions")
                        Spacer()
                        Text("\(QuestionBank.all.count)").foregroundStyle(Theme.textSecondary(scheme))
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0").foregroundStyle(Theme.textSecondary(scheme))
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background(scheme).ignoresSafeArea())
            .navigationTitle("Settings")
            .tint(Theme.accent)
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .confirmationDialog("Reset all progress?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset everything", role: .destructive) { reset() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your exam history and per-question stats. This cannot be undone.")
            }
            .alert("Progress reset", isPresented: $resetDone) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your study history has been cleared.")
            }
        }
    }

    /// Read-aloud is a Pro feature: turning it on without Pro opens the paywall.
    private var readAloudBinding: Binding<Bool> {
        Binding(
            get: { prefs.readAloud && prefs.isPro },
            set: { newValue in
                if newValue && !prefs.isPro {
                    showPaywall = true
                } else {
                    prefs.readAloud = newValue
                }
            }
        )
    }

    private func settingRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundStyle(Theme.textSecondary(scheme))
        }
    }

    private func reset() {
        for r in (try? context.fetch(FetchDescriptor<ExamResult>())) ?? [] { context.delete(r) }
        for s in (try? context.fetch(FetchDescriptor<QuestionStat>())) ?? [] { context.delete(s) }
        try? context.save()
        Haptics.warning(enabled: prefs.hapticsEnabled)
        resetDone = true
    }
}

/// Plain-language disclaimer.
struct DisclaimerView: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Study aid, not legal advice")
                    .font(Theme.sectionTitle)
                    .foregroundStyle(Theme.textPrimary(scheme))
                Text("Parcel's questions cover the national/general portion of real-estate licensing exams. They are written to help you study common concepts and are not a substitute for an approved pre-licensing course or your state's official materials.")
                Text("Real-estate law varies by state. State-specific rules — license requirements, agency disclosure forms, contract forms, deadlines, and math conventions like proration methods — are not covered here. Always confirm the rules for the state where you intend to be licensed.")
                Text("Nothing in this app is legal, financial, or tax advice.")
            }
            .font(.subheadline)
            .foregroundStyle(Theme.textSecondary(scheme))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
        .background(Theme.background(scheme).ignoresSafeArea())
        .navigationTitle("Disclaimer")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// About screen.
struct AboutView: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Parcel")
                    .font(Theme.largeTitle)
                    .foregroundStyle(Theme.textPrimary(scheme))
                Text("A calm, ad-free way to prep for your real-estate license exam. \(QuestionBank.all.count) exam-style questions across ten national topics, each with a clear explanation, plus adaptive drills and a readiness score — all on-device and private.")
                Text("One-time purchase. No subscriptions. No accounts. Your study data never leaves your device.")
            }
            .font(.subheadline)
            .foregroundStyle(Theme.textSecondary(scheme))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
        .background(Theme.background(scheme).ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

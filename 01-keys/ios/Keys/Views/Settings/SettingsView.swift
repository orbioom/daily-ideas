import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsQuery: [UserSettings]
    @Query private var sessions: [PracticeSession]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showResetAlert = false
    @State private var showProSheet = false

    private var settings: UserSettings? { settingsQuery.first }

    private let goalOptions = [5, 10, 15, 20]

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Practice
                Section("Practice") {
                    if let settings {
                        Toggle(isOn: Binding(
                            get: { settings.soundEnabled },
                            set: { settings.soundEnabled = $0 }
                        )) {
                            Label("Sound", systemImage: "speaker.wave.2.fill")
                        }
                        .tint(KeysTheme.accent)

                        Toggle(isOn: Binding(
                            get: { settings.hapticsEnabled },
                            set: { settings.hapticsEnabled = $0 }
                        )) {
                            Label("Haptics", systemImage: "iphone.radiowaves.left.and.right")
                        }
                        .tint(KeysTheme.accent)

                        Toggle(isOn: Binding(
                            get: { settings.showNoteLabels },
                            set: { settings.showNoteLabels = $0 }
                        )) {
                            Label("Show Note Labels", systemImage: "textformat.abc")
                        }
                        .tint(KeysTheme.accent)

                        Picker(selection: Binding(
                            get: { settings.dailyGoalMinutes },
                            set: { settings.dailyGoalMinutes = $0 }
                        )) {
                            ForEach(goalOptions, id: \.self) { mins in
                                Text("\(mins) min").tag(mins)
                            }
                        } label: {
                            Label("Daily Goal", systemImage: "target")
                        }
                    }
                }

                // MARK: Upgrade
                Section("Keys Pro") {
                    if settings?.hasPro == true {
                        HStack {
                            Label("Pro Unlocked", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(KeysTheme.accent)
                            Spacer()
                            Text("Thank you!")
                                .foregroundStyle(KeysTheme.textSecondary)
                        }
                    } else {
                        Button {
                            showProSheet = true
                        } label: {
                            HStack {
                                Label("Unlock Pro — $4.99", systemImage: "lock.open.fill")
                                    .foregroundStyle(KeysTheme.accent)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(KeysTheme.textSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                // MARK: Stats
                Section("Your Stats") {
                    LabeledContent("Streak") {
                        Text("\(settings?.streakCount ?? 0) days")
                    }
                    LabeledContent("Sessions Completed") {
                        Text("\(sessions.count)")
                    }
                    LabeledContent("Lessons Completed") {
                        Text("\(settings?.completedLessons.count ?? 0)")
                    }
                }

                // MARK: Data
                Section("Data") {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("Reset All Progress", systemImage: "arrow.counterclockwise")
                    }
                }

                // MARK: About
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Bundle ID", value: "com.orbioom.keys")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KeysTheme.accent)
                }
            }
            .alert("Reset Progress?", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) { resetProgress() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all practice sessions and lesson progress. This cannot be undone.")
            }
            .sheet(isPresented: $showProSheet) {
                ProUpgradeView()
            }
        }
    }

    private func resetProgress() {
        for session in sessions {
            modelContext.delete(session)
        }
        if let settings = settingsQuery.first {
            settings.streakCount = 0
            settings.lastPracticeDate = nil
            settings.completedLessons = []
        }
    }
}

struct ProUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsQuery: [UserSettings]
    @State private var isPurchasing = false

    private let features = [
        ("music.quarternote.3", "Full Song Library", "50+ songs from classical to pop"),
        ("waveform", "Advanced Exercises", "Scales, arpeggios, and more"),
        ("chart.bar.fill", "Detailed Analytics", "Deep dive into your practice data"),
        ("icloud.fill", "iCloud Sync", "Sync progress across your devices")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Hero
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(KeysTheme.accent.opacity(0.15))
                                .frame(width: 100, height: 100)
                            Image(systemName: "pianokeys.inverse")
                                .font(.system(size: 44))
                                .foregroundStyle(KeysTheme.accent)
                        }

                        Text("Keys Pro")
                            .font(.largeTitle.bold())
                        Text("One-time purchase. No subscription.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 32)

                    // Features
                    VStack(spacing: 16) {
                        ForEach(features, id: \.0) { icon, title, desc in
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(KeysTheme.accent.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: icon)
                                        .foregroundStyle(KeysTheme.accent)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(title)
                                        .font(.subheadline.weight(.semibold))
                                    Text(desc)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Purchase button
                    VStack(spacing: 12) {
                        Button {
                            simulatePurchase()
                        } label: {
                            Group {
                                if isPurchasing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Unlock for $4.99")
                                        .font(.headline.bold())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .foregroundStyle(.white)
                            .background(KeysTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isPurchasing)

                        Button("Restore Purchase") {}
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 32)

                    Text("Payment is charged to your Apple ID account at confirmation of purchase. No subscription — pay once, own forever.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Spacer(minLength: 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func simulatePurchase() {
        isPurchasing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isPurchasing = false
            dismiss()
        }
    }
}

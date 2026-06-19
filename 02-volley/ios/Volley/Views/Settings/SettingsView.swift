import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsQuery: [AppSettings]
    @Query(filter: #Predicate<Question> { $0.isCustom == true }) private var customQuestions: [Question]
    @Query private var sessions: [GameSession]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showResetAlert = false
    @State private var showProSheet = false

    private var settings: AppSettings? { settingsQuery.first }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Gameplay
                Section("Gameplay") {
                    if let settings {
                        Toggle(isOn: Binding(
                            get: { settings.hapticsEnabled },
                            set: { settings.hapticsEnabled = $0 }
                        )) {
                            Label("Haptics", systemImage: "iphone.radiowaves.left.and.right")
                        }
                        .tint(VolleyTheme.accent)

                        Toggle(isOn: Binding(
                            get: { settings.safeMode },
                            set: { settings.safeMode = $0 }
                        )) {
                            Label("Safe Mode", systemImage: "shield.fill")
                        }
                        .tint(VolleyTheme.accent)

                        if settings.safeMode {
                            Text("Party category questions are hidden during games.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: Pro
                Section("Volley Pro") {
                    if settings?.hasPro == true {
                        HStack {
                            Label("Pro Unlocked", systemImage: "crown.fill")
                                .foregroundStyle(VolleyTheme.accent)
                            Spacer()
                            Text("Thank you!")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Button {
                            showProSheet = true
                        } label: {
                            HStack {
                                Label("Unlock Volley Pro — $1.99", systemImage: "lock.open.fill")
                                    .foregroundStyle(VolleyTheme.accent)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                // MARK: Stats
                Section("Your Stats") {
                    LabeledContent("Games Played") { Text("\(sessions.count)") }
                    LabeledContent("Questions Answered") {
                        Text("\(sessions.reduce(0) { $0 + $1.questionsAnswered })")
                    }
                    LabeledContent("Custom Questions") { Text("\(customQuestions.count)") }
                }

                // MARK: Data
                Section("Data") {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("Reset Custom Questions", systemImage: "trash")
                    }
                }

                // MARK: About
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Bundle ID", value: "com.orbioom.volley")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(VolleyTheme.accent)
                }
            }
            .alert("Reset Custom Questions?", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) { resetCustom() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your custom questions. Built-in questions are not affected.")
            }
            .sheet(isPresented: $showProSheet) {
                VolleyProSheet()
            }
        }
    }

    private func resetCustom() {
        for q in customQuestions {
            modelContext.delete(q)
        }
    }
}

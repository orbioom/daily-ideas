import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore

    @State private var showResetConfirm = false
    @State private var showPaywall = false
    @State private var toast: String?

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Pro
                Section {
                    if pro.isPro {
                        Label("Permit Pro is active", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Theme.good)
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("Unlock Permit Pro", systemImage: "crown.fill")
                                .foregroundStyle(Theme.accent)
                        }
                        Button("Restore Purchase") {
                            pro.restore()
                            toast = "Purchase restored"
                        }
                    }
                } header: { Text("Permit Pro") }

                // MARK: Appearance
                Section {
                    Picker("Appearance", selection: Binding(
                        get: { settings.appearance },
                        set: { settings.appearance = $0 }
                    )) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                } header: { Text("Appearance") }

                // MARK: Exams
                Section {
                    Picker("Mock length", selection: Binding(
                        get: { settings.mockLength },
                        set: { settings.mockLength = $0 }
                    )) {
                        ForEach(MockLength.allCases) { len in
                            Text(len.label).tag(len)
                        }
                    }
                    Toggle("Instant explanations in practice", isOn: $settings.instantExplanations)
                    Toggle("Show exam timer", isOn: $settings.showTimer)
                } header: { Text("Exams & Practice") } footer: {
                    Text("Full mocks require \(Int(ExamEngine.fullMockPassThreshold * 100))% to pass.")
                }

                // MARK: Feedback
                Section {
                    Toggle("Haptics", isOn: $settings.hapticsEnabled)
                    Toggle("Sound effects", isOn: $settings.soundEnabled)
                } header: { Text("Feedback") }

                // MARK: Study location
                Section {
                    TextField("Your state (optional)", text: $settings.studyState)
                        .textInputAutocapitalization(.words)
                } header: { Text("Study location") } footer: {
                    Text("Shown on your home screen. Permit teaches general US rules — confirm specifics in your state handbook.")
                }

                // MARK: Data
                Section {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("Reset all progress", systemImage: "trash")
                    }
                } header: { Text("Data") }

                // MARK: About
                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About Permit", systemImage: "info.circle")
                    }
                    HStack {
                        Text("Question bank")
                        Spacer()
                        Text("\(QuestionBank.count) questions").foregroundStyle(Theme.inkSoft)
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0").foregroundStyle(Theme.inkSoft)
                    }
                } header: { Text("About") }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .tint(Theme.accent)
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .toast($toast)
            .confirmationDialog("Reset all progress?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset everything", role: .destructive) {
                    StatStore.resetAll(in: context)
                    Haptics.warning(settings.hapticsEnabled)
                    toast = "Progress reset"
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your question stats, flags and exam history. This can't be undone.")
            }
        }
    }
}

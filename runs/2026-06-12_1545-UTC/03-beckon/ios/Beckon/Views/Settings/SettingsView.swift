import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var intentions: [Intention]

    @AppStorage("writingMode") private var writingMode = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("appearance") private var appearance = "system"
    @State private var showReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Writing mode", isOn: $writingMode).tint(Theme.accent)
                } header: {
                    Text("Ritual")
                } footer: {
                    Text(writingMode
                         ? "You type your affirmation each time — the heart of the 369 method."
                         : "Tap mode lets you affirm with a single tap instead of writing each line.")
                }
                Section("Appearance") {
                    Picker("Theme", selection: $appearance) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                }
                Section("Feedback") {
                    Toggle("Haptics", isOn: $hapticsEnabled).tint(Theme.accent)
                }
                Section {
                    LabeledContent("Intentions", value: "\(intentions.count)")
                    LabeledContent("Total affirmations", value: "\(PracticeEngine.totalReps(intentions))")
                } header: {
                    Text("Your practice")
                }
                Section {
                    Button(role: .destructive) { showReset = true } label: {
                        Label("Delete all intentions", systemImage: "trash")
                    }
                } footer: {
                    Text("Everything in Beckon stays on this iPhone — never uploaded. No account, no ads.")
                }
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Method", value: "369 · write 3 · 6 · 9")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bgPrimary.ignoresSafeArea())
            .navigationTitle("Settings")
            .preferredColorScheme(colorScheme)
            .confirmationDialog("Delete every intention and all practice history?",
                                isPresented: $showReset, titleVisibility: .visible) {
                Button("Delete everything", role: .destructive) { wipe() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var colorScheme: ColorScheme? {
        switch appearance { case "light": return .light; case "dark": return .dark; default: return nil }
    }

    private func wipe() {
        for i in intentions { context.delete(i) }
        try? context.save()
        Haptics.success()
    }
}

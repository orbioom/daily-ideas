import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("defaultStartScore") private var defaultStartScore = 501
    @AppStorage("defaultBestOf") private var defaultBestOf = 5
    @AppStorage("showAlternateRoutes") private var showAlternateRoutes = true
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    @Query private var matches: [Match]
    @Query private var sessions: [PracticeSession]

    @State private var confirmClear = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section {
                        Picker("Start score", selection: $defaultStartScore) {
                            Text("301").tag(301)
                            Text("501").tag(501)
                            Text("701").tag(701)
                        }
                        Picker("Match length", selection: $defaultBestOf) {
                            Text("Best of 3").tag(3)
                            Text("Best of 5").tag(5)
                            Text("Best of 7").tag(7)
                        }
                    } header: { Text("New match defaults") }
                        .listRowBackground(Color.clear)

                    Section {
                        Toggle("Show alternate routes", isOn: $showAlternateRoutes)
                        Toggle("Haptics", isOn: $hapticsEnabled)
                    } header: { Text("Preferences") } footer: {
                        Text("Alternate routes list a second and third way to finish each checkout.")
                    }
                    .listRowBackground(Color.clear)

                    Section {
                        LabeledContent("Matches logged", value: "\(matches.count)")
                        LabeledContent("Practice sessions", value: "\(sessions.count)")
                    } header: { Text("Your data") }
                        .listRowBackground(Color.clear)

                    Section {
                        Button("Replay intro") { hasOnboarded = false }
                            .foregroundStyle(Brand.text)
                        Button(role: .destructive) { confirmClear = true } label: {
                            Text("Clear all data")
                        }
                    } header: { Text("Manage") }
                        .listRowBackground(Color.clear)

                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Oche").font(.headline).foregroundStyle(Brand.text)
                            Text("A calm darts companion — matches, checkouts, and double practice. All on-device, no account.")
                                .font(.footnote).foregroundStyle(Brand.text2)
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
            .alert("Clear all data?", isPresented: $confirmClear) {
                Button("Delete everything", role: .destructive) { clearAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently removes every match and practice session. This cannot be undone.")
            }
        }
    }

    private func clearAll() {
        for m in matches { context.delete(m) }
        for s in sessions { context.delete(s) }
        try? context.save()
        Haptics.warning()
    }
}

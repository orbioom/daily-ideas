import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var library: PhotoLibraryService
    @Environment(\.modelContext) private var context
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("confirmDelete") private var confirmDelete = true

    @Query private var kept: [KeptPhoto]
    @State private var showResetKept = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section {
                        Toggle("Confirm before deleting", isOn: $confirmDelete)
                    } header: { Text("Safety") } footer: {
                        Text("iOS always shows its own deletion prompt. This adds an extra confirmation inside Sweep.")
                    }

                    Section("Appearance") {
                        Picker("Theme", selection: $appearance) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                    }

                    Section("Feedback") {
                        Toggle("Haptics", isOn: $hapticsEnabled)
                            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
                    }

                    Section {
                        HStack {
                            Text("Photos kept")
                            Spacer()
                            Text("\(kept.count)").foregroundStyle(Brand.text3).font(Brand.mono(15))
                        }
                        Button("Review kept photos again") { showResetKept = true }
                            .disabled(kept.isEmpty)
                    } header: { Text("Kept photos") } footer: {
                        Text("Kept photos are hidden from review decks. Reset to see them again. This never affects your actual library.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .alert("Review kept photos again?", isPresented: $showResetKept) {
                Button("Reset", role: .destructive) {
                    for k in kept { context.delete(k) }
                    try? context.save()
                    Haptics.warning()
                    Task { await library.scan(kept: []) }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

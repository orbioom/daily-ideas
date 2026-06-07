import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("defaultPosition") private var defaultPositionRaw = WatchPosition.onWrist.rawValue
    @AppStorage("defaultServiceYears") private var defaultServiceYears = 5
    @AppStorage("driftHorizonDays") private var driftHorizonDays = 7
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    @Query private var watches: [Watch]
    @State private var confirmClear = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section {
                        Picker("Default position", selection: $defaultPositionRaw) {
                            ForEach(WatchPosition.allCases) { p in
                                Text(p.label).tag(p.rawValue)
                            }
                        }
                        Stepper("Service interval: \(defaultServiceYears) yr",
                                value: $defaultServiceYears, in: 1...10)
                    } header: { Text("New watch defaults") }
                        .listRowBackground(Color.clear)

                    Section {
                        Picker("Drift horizon", selection: $driftHorizonDays) {
                            Text("1 day").tag(1); Text("1 week").tag(7); Text("1 month").tag(30)
                        }
                        Toggle("Haptics", isOn: $hapticsEnabled)
                    } header: { Text("Preferences") } footer: {
                        Text("Drift horizon sets how far ahead Caliber projects each watch's gain or loss.")
                    }
                    .listRowBackground(Color.clear)

                    Section {
                        LabeledContent("Watches", value: "\(watches.count)")
                        LabeledContent("Measurements",
                                       value: "\(watches.reduce(0) { $0 + $1.measurements.count })")
                    } header: { Text("Your data") }
                        .listRowBackground(Color.clear)

                    Section {
                        Button("Replay intro") { hasOnboarded = false }.foregroundStyle(Brand.text)
                        Button(role: .destructive) { confirmClear = true } label: { Text("Clear all data") }
                    } header: { Text("Manage") }
                        .listRowBackground(Color.clear)

                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Caliber").font(.headline).foregroundStyle(Brand.text)
                            Text("A calm accuracy log for mechanical watches. Least-squares rate, positional analysis, and service tracking — all on-device.")
                                .font(.footnote).foregroundStyle(Brand.text2)
                        }
                    }.listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
            .alert("Clear all data?", isPresented: $confirmClear) {
                Button("Delete everything", role: .destructive) { clearAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently removes every watch and reading. This cannot be undone.")
            }
        }
    }

    private func clearAll() {
        for w in watches { context.delete(w) }
        try? context.save()
        Haptics.warning()
    }
}

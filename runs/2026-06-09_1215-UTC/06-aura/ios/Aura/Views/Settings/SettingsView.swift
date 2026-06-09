import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var attacks: [Attack]

    @AppStorage("aura.haptics") private var haptics = true
    @AppStorage("aura.overuseThreshold") private var overuseThreshold = 10
    @AppStorage("aura.defaultType") private var defaultTypeRaw = HeadacheType.migraine.rawValue
    @AppStorage("aura.showImpact") private var showImpact = true
    @AppStorage("aura.onboarded") private var onboarded = true

    @State private var showDeleteConfirm = false

    private var defaultType: HeadacheType {
        HeadacheType(rawValue: defaultTypeRaw) ?? .migraine
    }

    var body: some View {
        Form {
            Section("Logging") {
                Picker("Default headache type", selection: Binding(
                    get: { defaultType },
                    set: { defaultTypeRaw = $0.rawValue })) {
                    ForEach(HeadacheType.allCases) { Text($0.label).tag($0) }
                }
                Toggle("Interface haptics", isOn: $haptics)
            }

            Section {
                Stepper("Acute-med limit: \(overuseThreshold) days / 30",
                        value: $overuseThreshold, in: 6...20)
                    .accessibilityValue("\(overuseThreshold) days per 30")
            } header: {
                Text("Medication-overuse warning")
            } footer: {
                Text("Aura warns you once acute medication has been taken on this many days in the last 30. Guidelines often cite around 10.")
            }

            Section("Insights") {
                Toggle("Show impact card", isOn: $showImpact)
            }

            Section("Your diary") {
                LabeledContent("Attacks logged", value: "\(attacks.count)")
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete all data", systemImage: "trash")
                }
                Button {
                    Haptics.tap()
                    onboarded = false
                } label: {
                    Label("Replay intro", systemImage: "sparkles")
                }
            } footer: {
                Text("Deleting removes every logged attack and its medications. Your trigger, symptom, and medication catalogs are kept.")
            }

            Section {
                LabeledContent("Aura", value: "1.0")
            } footer: {
                Text("Aura is a personal diary, not a medical device. It doesn't diagnose or treat — share it with your clinician. Everything stays on this device. Conjured, not just coded.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Settings")
        .confirmationDialog("Delete all attacks?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete everything", role: .destructive) { deleteAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes every logged attack. Your catalogs are untouched.")
        }
    }

    private func deleteAll() {
        for attack in attacks { context.delete(attack) }
        try? context.save()
        Haptics.warning()
    }
}

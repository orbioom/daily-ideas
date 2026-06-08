import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var fasts: [Fast]

    @AppStorage("ember.haptics") private var haptics = true
    @AppStorage("ember.showStages") private var showStages = true
    @AppStorage("ember.defaultStart") private var defaultStartEvening = true
    @AppStorage("ember.activePlanName") private var planName = "16:8"

    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Preferences") {
                        Toggle("Haptic feedback", isOn: $haptics)
                            .onChange(of: haptics) { _, v in Haptics.enabled = v }
                        Toggle("Show metabolic stages", isOn: $showStages)
                        Toggle("Default to evening start", isOn: $defaultStartEvening)
                    }

                    Section("Active plan") {
                        HStack {
                            Text("Current")
                            Spacer()
                            Text(planName).foregroundStyle(Brand.text2)
                        }
                        Text("Change your plan on the Plans tab.")
                            .font(.footnote)
                            .foregroundStyle(Brand.text3)
                    }

                    Section("Data") {
                        HStack {
                            Text("Fasts stored")
                            Spacer()
                            Text("\(fasts.count)").foregroundStyle(Brand.text2)
                        }
                        Button(role: .destructive) {
                            confirmReset = true
                        } label: {
                            Label("Delete all fasts", systemImage: "trash")
                        }
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ember 1.0")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Brand.text)
                            Text("All data stays on this device. Ember is for education and motivation, not medical advice — talk to a clinician before changing how you eat.")
                                .font(.footnote)
                                .foregroundStyle(Brand.text2)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .alert("Delete all fasts?", isPresented: $confirmReset) {
                Button("Delete", role: .destructive) {
                    for f in fasts { context.delete(f) }
                    try? context.save()
                    Haptics.warning()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently removes your fasting history. Plans are kept.")
            }
        }
    }
}

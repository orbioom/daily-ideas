import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsAll: [KegSettings]
    @Query private var recipes: [Recipe]
    @Environment(\.modelContext) private var context

    var settings: KegSettings {
        if let s = settingsAll.first { return s }
        let s = KegSettings()
        context.insert(s)
        return s
    }

    var totalBatches: Int { recipes.flatMap { $0.batches }.count }
    var completedBatches: Int { recipes.flatMap { $0.batches }.filter { $0.status == "complete" }.count }

    var body: some View {
        NavigationStack {
            Form {
                Section("Brewery") {
                    HStack {
                        Text("Brewery Name")
                        Spacer()
                        TextField("My Brewery", text: Binding(
                            get: { settings.breweryName },
                            set: { v in settings.breweryName = v; try? context.save() }
                        ))
                        .multilineTextAlignment(.trailing)
                    }
                }

                Section("Units") {
                    Toggle("Metric (liters/°C)", isOn: Binding(
                        get: { settings.useMetric },
                        set: { v in settings.useMetric = v; try? context.save() }
                    ))
                    Toggle("Celsius", isOn: Binding(
                        get: { settings.useCelsius },
                        set: { v in settings.useCelsius = v; try? context.save() }
                    ))
                }

                Section("Experience") {
                    Toggle("Haptic Feedback", isOn: Binding(
                        get: { settings.hapticsEnabled },
                        set: { v in settings.hapticsEnabled = v; try? context.save() }
                    ))
                }

                Section("Your Brewery Stats") {
                    LabeledContent("Total Recipes", value: "\(recipes.count)")
                    LabeledContent("Total Batches", value: "\(totalBatches)")
                    LabeledContent("Completed Batches", value: "\(completedBatches)")
                    LabeledContent("Favorite Recipes", value: "\(recipes.filter { $0.isFavorite }.count)")
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    Text("Keg is a homebrew companion app. Your recipes and batches are private and stored on-device only.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

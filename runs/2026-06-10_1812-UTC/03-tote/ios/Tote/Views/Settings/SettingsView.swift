import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("hideChecked") private var hideChecked = false
    @AppStorage("confirmClear") private var confirmClear = true

    @Query private var catalog: [CatalogItem]
    @Query private var items: [ListItem]
    @State private var showClearCatalog = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Shopping") {
                        Toggle("Hide items already in cart", isOn: $hideChecked)
                        Toggle("Confirm before clearing cart", isOn: $confirmClear)
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
                            Text("Remembered items")
                            Spacer()
                            Text("\(catalog.count)").foregroundStyle(Brand.text3).font(Brand.mono(15))
                        }
                        Button(role: .destructive) { showClearCatalog = true } label: {
                            Text("Clear remembered items")
                        }
                        .disabled(catalog.isEmpty)
                    } header: { Text("Data") } footer: {
                        Text("Tote keeps your lists and recipes on this device only.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .alert("Clear remembered items?", isPresented: $showClearCatalog) {
                Button("Clear", role: .destructive) {
                    for c in catalog { context.delete(c) }
                    try? context.save()
                    Haptics.warning()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This forgets your autocomplete and staples. Your lists and recipes are kept.")
            }
        }
    }
}

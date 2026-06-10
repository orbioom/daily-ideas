import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var projects: [CollageProject]

    @AppStorage("exportSize") private var exportSize = 2000
    @AppStorage("haptics") private var haptics = true
    @AppStorage("appearance") private var appearance = "system"
    @State private var showClear = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section {
                        Picker("Export resolution", selection: $exportSize) {
                            Text("Standard · 2000px").tag(2000)
                            Text("High · 3000px").tag(3000)
                            Text("Max · 4000px").tag(4000)
                        }
                    } header: {
                        Text("Export")
                    } footer: {
                        Text("Longest edge of the exported image. Exports never carry a watermark.")
                    }

                    Section("Appearance") {
                        Picker("Theme", selection: $appearance) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("Feedback") {
                        Toggle("Haptics", isOn: $haptics)
                            .tint(Brand.live)
                            .onChange(of: haptics) { _, v in Haptics.enabled = v }
                    }

                    Section {
                        Button(role: .destructive) { showClear = true } label: {
                            Label("Delete all collages", systemImage: "trash")
                        }
                    } footer: {
                        Text("\(projects.count) collages stored on this device.")
                    }

                    Section {
                        LabeledContent("Privacy", value: "Photos stay on device")
                        LabeledContent("Version", value: "1.0")
                    } header: {
                        Text("About")
                    } footer: {
                        Text("Mosaic imports photos privately and never uploads them. No ads, no watermark, no subscription on the core layouts and filters.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .preferredColorScheme(resolvedScheme)
            .confirmationDialog("Delete all collages?", isPresented: $showClear, titleVisibility: .visible) {
                Button("Delete all", role: .destructive) { clearAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently removes every collage and its photos from this device.")
            }
        }
    }

    private var resolvedScheme: ColorScheme? {
        switch appearance { case "light": .light; case "dark": .dark; default: nil }
    }

    private func clearAll() {
        for p in projects {
            for cell in p.cells { ImageStore.delete(cell.imageFile) }
            ImageStore.delete(p.thumbnailFile)
            context.delete(p)
        }
        try? context.save()
        Haptics.warning()
    }
}

#Preview {
    SettingsView().modelContainer(for: CollageProject.self, inMemory: true)
}

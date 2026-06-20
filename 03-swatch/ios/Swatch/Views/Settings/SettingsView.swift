import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var ctx
    @Query private var palettes: [Palette]
    @AppStorage("preferredColorCount") private var preferredColorCount = 6
    @State private var showClearAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                SwatchTheme.bg.ignoresSafeArea()

                Form {
                    Section {
                        Stepper("Default color count: \(preferredColorCount)", value: $preferredColorCount, in: 4...8)
                    } header: {
                        Text("Extraction")
                    }

                    Section {
                        HStack {
                            Text("Saved palettes")
                            Spacer()
                            Text("\(palettes.count)")
                                .foregroundStyle(SwatchTheme.subtleText)
                        }

                        Button(role: .destructive) {
                            showClearAlert = true
                        } label: {
                            Label("Clear All Palettes", systemImage: "trash")
                                .foregroundStyle(.red)
                        }
                    } header: {
                        Text("Data")
                    }

                    Section {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundStyle(SwatchTheme.subtleText)
                        }
                        HStack {
                            Text("Theme")
                            Spacer()
                            Text("Light")
                                .foregroundStyle(SwatchTheme.subtleText)
                        }
                    } header: {
                        Text("About")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .alert("Clear All Palettes?", isPresented: $showClearAlert) {
                Button("Clear All", role: .destructive) {
                    clearAllPalettes()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all \(palettes.count) saved palettes.")
            }
        }
    }

    private func clearAllPalettes() {
        for palette in palettes {
            ctx.delete(palette)
        }
        try? ctx.save()
    }
}

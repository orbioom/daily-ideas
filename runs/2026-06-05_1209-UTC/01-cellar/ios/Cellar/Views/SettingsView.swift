import SwiftUI
import SwiftData

/// Real, persisted preferences. Every control here changes behavior and survives relaunch.
struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Query private var bottles: [Bottle]

    @State private var showingResetConfirm = false
    @State private var showingClearConfirm = false
    @State private var feedback: String?

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $settings.appearance) {
                        ForEach(SettingsStore.Appearance.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Picker("Default sort", selection: $settings.defaultSort) {
                        ForEach(SettingsStore.SortOrder.allCases) { order in
                            Text(order.title).tag(order)
                        }
                    }
                    Toggle("Haptic feedback", isOn: $settings.hapticsEnabled)
                } header: {
                    Text("Cellar")
                } footer: {
                    Text("Default sort applies the next time you open the Cellar tab.")
                }

                Section {
                    HStack {
                        Label("Bottles", systemImage: "archivebox")
                        Spacer()
                        Text("\(bottles.count)").font(Brand.mono(15)).foregroundStyle(Brand.text2)
                    }
                    HStack {
                        Label("Tastings", systemImage: "drop")
                        Spacer()
                        Text("\(bottles.reduce(0) { $0 + $1.tastingCount })")
                            .font(Brand.mono(15)).foregroundStyle(Brand.text2)
                    }
                } header: {
                    Text("Your data")
                } footer: {
                    Text("Everything stays on this device, stored with SwiftData. Nothing leaves your phone.")
                }

                Section("Manage") {
                    Button {
                        showingResetConfirm = true
                    } label: {
                        Label("Reset to sample cellar", systemImage: "arrow.counterclockwise")
                    }
                    Button(role: .destructive) {
                        showingClearConfirm = true
                    } label: {
                        Label("Clear all data", systemImage: "trash")
                    }
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0").font(Brand.mono(15)).foregroundStyle(Brand.text3)
                    }
                    HStack {
                        Text("Made by")
                        Spacer()
                        Text("Orbioom").foregroundStyle(Brand.text2)
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("Cellar — conjured, not just coded.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Settings")
            .alert("Reset to sample cellar?", isPresented: $showingResetConfirm) {
                Button("Reset", role: .destructive) { resetToSample() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This replaces everything currently in your cellar with the original sample bottles.")
            }
            .alert("Clear all data?", isPresented: $showingClearConfirm) {
                Button("Delete everything", role: .destructive) { clearAll() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Every bottle and tasting will be permanently removed. This can't be undone.")
            }
            .overlay(alignment: .bottom) {
                if let feedback {
                    Text(feedback)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Brand.inkGradient, in: Capsule())
                        .padding(.bottom, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .accessibilityAddTraits(.isStaticText)
                }
            }
        }
    }

    private func resetToSample() {
        do {
            try SampleData.clear(context)
            SampleData.insert(into: context)
            Haptics.success(enabled: settings.hapticsEnabled)
            flash("Sample cellar restored")
        } catch {
            flash("Couldn't reset — please try again")
        }
    }

    private func clearAll() {
        do {
            try SampleData.clear(context)
            Haptics.warning(enabled: settings.hapticsEnabled)
            flash("All data cleared")
        } catch {
            flash("Couldn't clear — please try again")
        }
    }

    private func flash(_ message: String) {
        withAnimation(Brand.ease()) { feedback = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(Brand.ease()) { feedback = nil }
        }
    }
}

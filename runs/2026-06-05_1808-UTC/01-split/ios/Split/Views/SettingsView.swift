import SwiftUI
import SwiftData

/// Real, persisted preferences. Every control here changes behavior and survives relaunch.
struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Query private var groups: [SplitGroup]

    @State private var showingResetConfirm = false
    @State private var showingClearConfirm = false
    @State private var toast: String?

    private var totalExpenses: Int { groups.reduce(0) { $0 + $1.expenses.count } }
    private var totalMembers: Int { groups.reduce(0) { $0 + $1.members.count } }

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
                    Picker("Default split", selection: $settings.defaultSplitMode) {
                        ForEach(SplitMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    Picker("Default currency", selection: $settings.defaultCurrencyCode) {
                        ForEach(Currency.all) { currency in
                            Text("\(currency.symbol)  \(currency.name)").tag(currency.code)
                        }
                    }
                    Toggle("Haptic feedback", isOn: $settings.hapticsEnabled)
                } header: {
                    Text("New expenses & groups")
                } footer: {
                    Text("Defaults apply to the next expense or group you create.")
                }

                Section {
                    HStack {
                        Label("Groups", systemImage: "person.2")
                        Spacer()
                        Text("\(groups.count)").font(Brand.mono(15)).foregroundStyle(Brand.text2)
                    }
                    HStack {
                        Label("Members", systemImage: "person")
                        Spacer()
                        Text("\(totalMembers)").font(Brand.mono(15)).foregroundStyle(Brand.text2)
                    }
                    HStack {
                        Label("Expenses", systemImage: "tray.full")
                        Spacer()
                        Text("\(totalExpenses)").font(Brand.mono(15)).foregroundStyle(Brand.text2)
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
                        Label("Reset to sample data", systemImage: "arrow.counterclockwise")
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
                    Text("Split — conjured, not just coded.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Settings")
            .alert("Reset to sample data?", isPresented: $showingResetConfirm) {
                Button("Reset", role: .destructive) { resetToSample() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This replaces everything currently in Split with the original sample groups.")
            }
            .alert("Clear all data?", isPresented: $showingClearConfirm) {
                Button("Delete everything", role: .destructive) { clearAll() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Every group, member, expense, and payment will be permanently removed. This can't be undone.")
            }
            .overlay(alignment: .bottom) {
                if let toast { ToastView(message: toast) }
            }
        }
    }

    private func resetToSample() {
        do {
            try SampleData.clear(context)
            SampleData.insert(into: context)
            Haptics.success(enabled: settings.hapticsEnabled)
            flash("Sample data restored")
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
        withAnimation(Brand.ease()) { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(Brand.ease()) { toast = nil }
        }
    }
}

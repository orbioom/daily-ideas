import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Environment(\.modelContext) private var context
    @State private var showPaywall = false
    @State private var showResetConfirm = false
    @State private var showRestoredToast = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Pro
                Section {
                    if isPro {
                        HStack {
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.good)
                            Text("Hark Pro unlocked")
                                .font(Theme.rounded(16, .semibold))
                                .foregroundStyle(Theme.ink)
                        }
                        .accessibilityElement(children: .combine)
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Image(systemName: "sparkles").foregroundStyle(Theme.accent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Unlock Hark Pro")
                                        .font(Theme.rounded(16, .semibold))
                                        .foregroundStyle(Theme.ink)
                                    Text("History, trends, all tools, export — \(Pro.priceLabel) once")
                                        .font(Theme.rounded(13))
                                        .foregroundStyle(Theme.inkSoft)
                                }
                            }
                        }
                        Button("Restore purchase") {
                            // Simulated restore (StoreKit-ready).
                            withAnimation { showRestoredToast = true }
                            Task {
                                try? await Task.sleep(nanoseconds: 1_500_000_000)
                                withAnimation { showRestoredToast = false }
                            }
                        }
                        .font(Theme.rounded(15))
                    }
                } header: {
                    Text("Hark Pro")
                }

                // MARK: Appearance
                Section {
                    Picker("Appearance", selection: Binding(
                        get: { settings.appearance },
                        set: { settings.appearance = $0 }
                    )) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    Toggle("Haptics", isOn: $settings.hapticsEnabled)
                } header: {
                    Text("Appearance & feedback")
                }

                // MARK: Test settings
                Section {
                    Picker("Test ear order", selection: Binding(
                        get: { settings.earOrder },
                        set: { settings.earOrder = $0 }
                    )) {
                        ForEach(EarOrder.allCases) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Tone duration")
                            Spacer()
                            Text(String(format: "%.1fs", settings.toneDuration))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Slider(value: $settings.toneDuration, in: 0.8...2.5, step: 0.1)
                            .tint(Theme.accent)
                            .accessibilityValue(String(format: "%.1f seconds", settings.toneDuration))
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Response timeout")
                            Spacer()
                            Text(String(format: "%.1fs", settings.responseTimeout))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Slider(value: $settings.responseTimeout, in: 2.0...5.0, step: 0.5)
                            .tint(Theme.accent)
                            .accessibilityValue(String(format: "%.1f seconds", settings.responseTimeout))
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Max test level")
                            Spacer()
                            Text("\(Int(settings.maxTestLevel)) dB")
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Slider(value: $settings.maxTestLevel, in: 60...100, step: 5)
                            .tint(Theme.accent)
                            .accessibilityValue("\(Int(settings.maxTestLevel)) decibels")
                        Text("The loudest relative level the screening will reach.")
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.inkSoft)
                    }
                } header: {
                    Text("Screening")
                } footer: {
                    Text("These shape how the next screening runs. They don't change past results.")
                }

                // MARK: Data
                Section {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Text("Erase all data")
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("Everything in Hark stays on this device.")
                }

                // MARK: About
                Section {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Made for", value: "Curious ears")
                    Text("Hark is an uncalibrated screening tool, not a medical device. It can't diagnose hearing loss. See a professional for sudden changes, pain, or one-sided symptoms.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                } header: {
                    Text("About")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .overlay(alignment: .top) {
                if showRestoredToast {
                    SuccessToast(message: "Nothing to restore yet")
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .confirmationDialog("Erase all data?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Erase everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently deletes all tests and saved matches on this device.")
            }
        }
    }

    private func eraseAll() {
        do {
            try context.delete(model: HearingTest.self)
            try context.delete(model: Threshold.self)
            try context.delete(model: TinnitusMatch.self)
            try context.save()
        } catch {
            // Non-fatal; leave data as-is if deletion fails.
        }
    }
}

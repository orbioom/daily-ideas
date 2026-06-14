import SwiftUI
import SwiftData

/// Settings: real, persisted prefs plus Pro/restore and About.
struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @AppStorage("isPro") private var isPro = false
    @Query private var events: [CountdownEvent]

    @State private var paywall: PaywallReason?
    @State private var showAbout = false
    @State private var confirmResetPro = false

    var body: some View {
        NavigationStack {
            Form {
                proSection
                defaultsSection
                appearanceSection
                feedbackSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(item: $paywall) { reason in PaywallView(reason: reason) }
            .sheet(isPresented: $showAbout) { AboutView() }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Theme.good.opacity(0.18)).frame(width: 40, height: 40)
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Theme.good)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cusp Pro active").font(Theme.rounded(16, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("Thank you for your support.")
                            .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            } else {
                Button {
                    paywall = .general
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Theme.accentSoft).frame(width: 40, height: 40)
                            Image(systemName: "sparkles").foregroundStyle(Theme.accent)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unlock Cusp Pro").font(Theme.rounded(16, .semibold))
                                .foregroundStyle(Theme.ink)
                            Text("Unlimited events, all themes, sharing & calendar")
                                .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.inkFaint)
                    }
                }
            }
        } footer: {
            if !isPro {
                Text("Free includes up to \(Pro.freeEventLimit) events and full counting — no ads, ever.")
            }
        }
    }

    // MARK: Defaults

    private var defaultsSection: some View {
        Section("New event defaults") {
            Picker("Default type", selection: $settings.defaultKind) {
                ForEach(EventKind.allCases) { Text($0.title).tag($0) }
            }

            Picker("Default gradient", selection: $settings.defaultThemeTag) {
                ForEach(CardTheme.allCases.filter { Pro.canUse(theme: $0, isPro: isPro) }) { theme in
                    Text(theme.name).tag(theme.rawValue)
                }
            }
        }
    }

    // MARK: Appearance / behavior

    private var appearanceSection: some View {
        Section("Display") {
            Toggle("Week starts on Monday", isOn: $settings.weekStartsMonday)
            Toggle("Show seconds on cards", isOn: $settings.showSecondsOnCards)
        } footer: {
            Text("Seconds appear on cards for events that include a time. The list ticks live when enabled.")
        }
    }

    private var feedbackSection: some View {
        Section("Feedback") {
            Toggle("Haptics", isOn: $settings.hapticsEnabled)
        }
    }

    // MARK: About

    private var aboutSection: some View {
        Section {
            Button {
                showAbout = true
            } label: {
                HStack {
                    Label("About Cusp", systemImage: "info.circle")
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.inkFaint)
                }
            }

            #if DEBUG
            if isPro {
                Button(role: .destructive) {
                    confirmResetPro = true
                } label: {
                    Label("Reset Pro (debug)", systemImage: "arrow.counterclockwise")
                }
                .confirmationDialog("Reset Pro for testing?", isPresented: $confirmResetPro, titleVisibility: .visible) {
                    Button("Reset", role: .destructive) { isPro = false }
                    Button("Cancel", role: .cancel) {}
                }
            }
            #endif
        } footer: {
            Text("Cusp \(appVersion) · \(events.count) event\(events.count == 1 ? "" : "s") tracked")
        }
    }

    private var appVersion: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return v ?? "1.0"
    }
}

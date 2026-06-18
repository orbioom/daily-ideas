import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @State private var showPaywall = false
    @State private var showRestoredToast = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        proCard
                        appearanceCard
                        trainingCard
                        feedbackCard
                        aboutCard
                    }
                    .padding(16)
                }
                if showRestoredToast {
                    VStack {
                        Spacer()
                        SuccessToast(text: isPro ? "Pro restored" : "Nothing to restore")
                            .padding(.bottom, 30)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var proCard: some View {
        Card {
            if isPro {
                HStack(spacing: 14) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.good)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fetch Pro active")
                            .font(Theme.rounded(17, .bold))
                            .foregroundStyle(Theme.ink)
                        Text("Thank you for your support!")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Theme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unlock Fetch Pro")
                                .font(Theme.rounded(17, .bold))
                                .foregroundStyle(Theme.ink)
                            Text("Unlimited dogs, all programs, advanced stats")
                                .font(Theme.rounded(13))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                    }
                    Button("See Pro") { showPaywall = true }
                        .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
    }

    private var appearanceCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Appearance", systemImage: "paintbrush.fill")
                Picker("Appearance", selection: Binding(
                    get: { settings.appearance },
                    set: { settings.appearance = $0 }
                )) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var trainingCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Training", systemImage: "figure.run")

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Daily goal")
                            .font(Theme.rounded(15, .medium))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text("\(settings.dailyGoalClamped) min")
                            .font(Theme.rounded(15, .bold))
                            .foregroundStyle(Theme.accent)
                    }
                    Stepper("Daily goal", value: $settings.dailyGoalMinutes, in: 5...120, step: 5)
                        .labelsHidden()
                }

                Divider().background(Theme.hairline)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Default session length")
                            .font(Theme.rounded(15, .medium))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text("\(settings.defaultSessionClamped) min")
                            .font(Theme.rounded(15, .bold))
                            .foregroundStyle(Theme.accent)
                    }
                    Stepper("Session length", value: $settings.defaultSessionMinutes, in: 1...30)
                        .labelsHidden()
                }

                Divider().background(Theme.hairline)

                Toggle(isOn: $settings.clickerSoundEnabled) {
                    Label("Clicker sound", systemImage: "speaker.wave.2.fill")
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.ink)
                }
                .tint(Theme.accent)
            }
        }
    }

    private var feedbackCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Feedback", systemImage: "iphone.radiowaves.left.and.right")
                Toggle(isOn: $settings.hapticsEnabled) {
                    Label("Haptics", systemImage: "hand.tap.fill")
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.ink)
                }
                .tint(Theme.accent)
            }
        }
    }

    private var aboutCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "About", systemImage: "info.circle.fill")
                Button {
                    isPro = isPro // restore is a no-op when already pro; simulated
                    withAnimation { showRestoredToast = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                        withAnimation { showRestoredToast = false }
                    }
                } label: {
                    HStack {
                        Label("Restore purchases", systemImage: "arrow.clockwise")
                            .font(Theme.rounded(15, .medium))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                    }
                }
                Divider().background(Theme.hairline)
                infoRow(label: "Version", value: "1.0")
                infoRow(label: "Tricks in catalog", value: "\(TrickCatalog.all.count)")
                infoRow(label: "Training programs", value: "\(ProgramCatalog.all.count)")
                Text("Fetch is a one-time purchase. No subscriptions, no ads, ever.")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
                    .padding(.top, 4)
            }
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value)
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(Theme.ink)
        }
    }
}

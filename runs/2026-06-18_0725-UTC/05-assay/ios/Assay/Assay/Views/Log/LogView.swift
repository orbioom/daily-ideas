import SwiftUI
import SwiftData

/// The Log tab — an entry point that explains logging and opens the panel
/// composer. Also surfaces free-tier limits and quick stats.
struct LogView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @Query private var results: [LabResult]

    @State private var showComposer = false
    @State private var showPaywall = false

    private var panelCount: Int {
        Set(results.map { $0.panelId }).count
    }

    private var atFreePanelCap: Bool {
        !pro.isPro && panelCount >= ProStore.freePanelCap
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        heroCard
                        if atFreePanelCap { capCard }
                        tipsCard
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Log")
            .sheet(isPresented: $showComposer) { LogPanelSheet() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var heroCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(Theme.accentSoft).frame(width: 76, height: 76)
                Image(systemName: "plus.viewfinder")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            Text("Log a blood draw")
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.ink)
            Text("Add one marker or a whole panel for a draw date. Enter the value, unit and lab — Assay scores each result for you.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Haptics.impact(.light, enabled: settings.hapticsEnabled)
                if atFreePanelCap {
                    showPaywall = true
                } else {
                    showComposer = true
                }
            } label: {
                Text("New panel")
                    .font(Theme.rounded(16, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .assayCard(padding: 22)
    }

    private var capCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Free panel limit reached", systemImage: "lock.fill")
                .font(Theme.rounded(15, .bold))
                .foregroundStyle(Theme.ink)
            Text("The free version stores up to \(ProStore.freePanelCap) panels. Unlock Assay Pro for unlimited panels, full history, export and custom markers.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                showPaywall = true
            } label: {
                Text("Unlock Pro")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.top, 2)
        }
        .assayCard()
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tips")
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.ink)
            tip("calendar", "Group results from the same draw under one date so they appear together.")
            tip("ruler", "Pick the unit shown on your lab report — Assay converts to its canonical scale automatically.")
            tip("lock.shield", "Everything stays on this device. Export a report only when you choose to.")
        }
        .assayCard()
    }

    private func tip(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Theme.accent)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

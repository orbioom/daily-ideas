import SwiftUI

struct PaywallView: View {
    let reason: PaywallReason
    @AppStorage("isPro") private var isPro = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var showRestoredNote = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    unlockList
                    fairnessNote
                    Spacer(minLength: 8)
                    buttons
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(Pro.productTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.inkFaint)
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Theme.heroGradient)
                    .frame(width: 96, height: 96)
                Image(systemName: "ticket.fill")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
            Text(reason.title)
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(reason.message)
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    private var unlockList: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Pro.unlocks, id: \.self) { line in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                    Text(line)
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .cardSurface()
    }

    private var fairnessNote: some View {
        Text("One fair, one-time unlock — no subscription, no ads, no account. Everything stays private on your device.")
            .font(Theme.rounded(13))
            .foregroundStyle(Theme.inkFaint)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var buttons: some View {
        VStack(spacing: 10) {
            PrimaryButton(title: "Unlock for \(Pro.priceLabel)", systemImage: "lock.open.fill") {
                Haptics.success(enabled: settings.hapticsEnabled)
                isPro = true
                dismiss()
            }
            Button("Restore purchase") {
                // Local simulation: a real build queries StoreKit's transaction history.
                if isPro {
                    dismiss()
                } else {
                    withAnimation { showRestoredNote = true }
                }
            }
            .font(Theme.rounded(15, .medium))
            .foregroundStyle(Theme.accent)

            if showRestoredNote {
                Text("No previous purchase found on this device.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkFaint)
                    .transition(.opacity)
            }
        }
    }
}

import SwiftUI

/// About sheet: what Tessera is, how secrets are protected, and the standards used.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Theme.accentSoft)
                            .frame(width: 96, height: 96)
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 46))
                            .foregroundStyle(Theme.accent)
                    }
                    .padding(.top, 8)
                    .accessibilityHidden(true)

                    Text("Tessera")
                        .font(Theme.rounded(28, .bold))
                        .foregroundStyle(Theme.ink)
                    Text("A private, offline two-factor authenticator. Your codes live on this device and nowhere else.")
                        .font(Theme.rounded(16))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 12)

                    infoCard(title: "How your secrets are stored",
                             symbol: "lock.doc",
                             body: "Secrets are kept in the app's local database, protected by iOS Data Protection and your optional Face ID / Touch ID app lock. In this build there is no extra application-layer encryption — your device passcode is the key. Nothing is ever uploaded.")

                    infoCard(title: "Standards",
                             symbol: "checkmark.seal",
                             body: "Codes follow RFC 4226 (HOTP) and RFC 6238 (TOTP) with HMAC-SHA1/256/512 via Apple CryptoKit. Import and export use the standard otpauth:// Key URI format, so you're never locked in.")

                    infoCard(title: "No account, no tracking",
                             symbol: "hand.raised",
                             body: "Tessera has no sign-in, no analytics, and no network calls for your data. The camera is used only when you choose to scan a QR code.")

                    Text("Version 1.0")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkFaint)
                        .padding(.top, 4)
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func infoCard(title: String, symbol: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(Theme.rounded(16, .semibold))
                .foregroundStyle(Theme.ink)
            Text(body)
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
    }
}

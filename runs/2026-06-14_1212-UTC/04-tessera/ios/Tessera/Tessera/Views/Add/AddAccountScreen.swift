import SwiftUI
import SwiftData

/// The "Add" tab: a hub offering three real import paths.
struct AddAccountScreen: View {
    var body: some View {
        NavigationStack {
            AddHubContent(showsDismiss: false)
                .navigationTitle("Add account")
        }
    }
}

/// The same hub presented as a modal sheet (from empty state / toolbar).
struct AddAccountSheet: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            AddHubContent(showsDismiss: true)
                .navigationTitle("Add account")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

/// Shared hub body: Scan QR · Paste link · Enter manually.
private struct AddHubContent: View {
    @Environment(\.dismiss) private var dismiss
    let showsDismiss: Bool

    @State private var destination: AddDestination?

    private enum AddDestination: String, Identifiable, Hashable {
        case scan, paste, manual
        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                option(icon: "qrcode.viewfinder",
                       title: "Scan QR code",
                       subtitle: "Point your camera at the setup QR your provider shows.",
                       tint: Theme.accent) {
                    destination = .scan
                }
                option(icon: "link",
                       title: "Paste setup link",
                       subtitle: "Paste an otpauth:// link and preview it before saving.",
                       tint: Theme.good) {
                    destination = .paste
                }
                option(icon: "keyboard",
                       title: "Enter manually",
                       subtitle: "Type the issuer, account, and Base32 secret yourself.",
                       tint: Theme.warn) {
                    destination = .manual
                }
                Spacer(minLength: 8)
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationDestination(item: $destination) { dest in
            switch dest {
            case .scan:
                ScanPathView { afterSave() }
            case .paste:
                PastePathView { afterSave() }
            case .manual:
                AccountEditorView(onSaved: { afterSave() })
            }
        }
    }

    private func afterSave() {
        destination = nil
        if showsDismiss { dismiss() }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "plus.viewfinder")
                .font(.system(size: 44))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Add a 2FA account")
                .font(Theme.rounded(22, .bold))
                .foregroundStyle(Theme.ink)
            Text("Pick how you want to import it. Everything stays on this device.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private func option(icon: String, title: String, subtitle: String,
                        tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(0.16))
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(tint)
                }
                .frame(width: 50, height: 50)
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(Theme.rounded(17, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(subtitle)
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
        }
        .buttonStyle(.plain)
        .accessibilityHint(subtitle)
    }
}

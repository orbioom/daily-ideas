import SwiftUI
import UIKit

/// Paste-link path. Parses an otpauth:// URI as you type, shows a live preview,
/// and continues to the editor (prefilled) so the user can confirm before saving.
struct PastePathView: View {
    @EnvironmentObject private var settings: AppSettings
    let onSaved: () -> Void

    @State private var text = ""
    @State private var goToEditor = false

    private var parsed: OTPAuthURI? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return OTPAuthURI.parse(trimmed)
    }

    private var hasInput: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Paste a setup link")
                    .font(Theme.rounded(20, .bold))
                    .foregroundStyle(Theme.ink)
                Text("It starts with otpauth:// and is what's inside a 2FA QR code.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)

                TextEditor(text: $text)
                    .font(Theme.mono(14))
                    .frame(minHeight: 110)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.hairline))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .accessibilityLabel("Setup link")

                HStack(spacing: 10) {
                    Button {
                        if let clip = UIPasteboard.general.string {
                            text = clip
                            Haptics.tap(settings.hapticsEnabled)
                        }
                    } label: {
                        Label("Paste from clipboard", systemImage: "doc.on.clipboard")
                            .font(Theme.rounded(14, .semibold))
                    }
                    Spacer()
                    if hasInput {
                        Button {
                            text = ""
                        } label: {
                            Label("Clear", systemImage: "xmark.circle")
                                .font(Theme.rounded(14, .semibold))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }
                }

                if let parsed {
                    Text("Preview")
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.inkFaint)
                    URIPreviewCard(uri: parsed)
                    PrimaryButton(title: "Continue", systemImage: "arrow.right") {
                        goToEditor = true
                    }
                } else if hasInput {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Theme.bad)
                        Text("That doesn't look like a valid otpauth:// link.")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.bad)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Paste link")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $goToEditor) {
            if let parsed {
                AccountEditorView(prefill: parsed, onSaved: onSaved)
            }
        }
    }
}

/// A compact read-only summary of a parsed otpauth URI.
struct URIPreviewCard: View {
    let uri: OTPAuthURI

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.accentSoft)
                    Text(monogram)
                        .font(Theme.rounded(18, .bold))
                        .foregroundStyle(Theme.accent)
                }
                .frame(width: 42, height: 42)
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(uri.issuer.isEmpty ? uri.accountName : uri.issuer)
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.ink)
                    if !uri.issuer.isEmpty {
                        Text(uri.accountName)
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                Spacer()
            }
            HStack(spacing: 6) {
                Pill(text: uri.type.shortName, systemImage: "clock", tint: Theme.accent)
                Pill(text: uri.algorithm.displayName, tint: Theme.inkSoft)
                Pill(text: "\(uri.digits) digits", tint: Theme.inkSoft)
                if uri.type == .totp {
                    Pill(text: "\(uri.period)s", tint: Theme.inkSoft)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
    }

    private var monogram: String {
        let src = (uri.issuer.isEmpty ? uri.accountName : uri.issuer).trimmingCharacters(in: .whitespaces)
        guard let first = src.first else { return "?" }
        return String(first).uppercased()
    }
}

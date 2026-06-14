import SwiftUI
import SwiftData
import UIKit

/// Paste a block of otpauth:// lines and import the valid ones. Shows a live
/// count of how many will import and how many lines were skipped.
struct ImportTextView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query private var existing: [Account]

    @State private var text = ""
    @State private var resultMessage: String?
    @State private var showPaywall = false

    private var parsed: (uris: [OTPAuthURI], skipped: Int) {
        BackupText.parse(text)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Paste exported lines")
                        .font(Theme.rounded(18, .bold))
                        .foregroundStyle(Theme.ink)
                    Text("One otpauth:// URI per line. Comment lines starting with # are ignored.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)

                    TextEditor(text: $text)
                        .font(Theme.mono(13))
                        .frame(minHeight: 150)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.hairline))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .accessibilityLabel("Import text")

                    Button {
                        if let clip = UIPasteboard.general.string { text = clip }
                    } label: {
                        Label("Paste from clipboard", systemImage: "doc.on.clipboard")
                            .font(Theme.rounded(14, .semibold))
                    }

                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        HStack(spacing: 12) {
                            Label("\(parsed.uris.count) ready", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(Theme.good)
                            if parsed.skipped > 0 {
                                Label("\(parsed.skipped) skipped", systemImage: "minus.circle")
                                    .foregroundStyle(Theme.inkFaint)
                            }
                        }
                        .font(Theme.rounded(14, .semibold))
                    }

                    if let resultMessage {
                        Text(resultMessage)
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.accent)
                    }

                    PrimaryButton(title: "Import \(parsed.uris.count) account\(parsed.uris.count == 1 ? "" : "s")",
                                  systemImage: "square.and.arrow.down",
                                  enabled: !parsed.uris.isEmpty) {
                        performImport()
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(reason: .accountLimit)
            }
        }
    }

    private func performImport() {
        let uris = parsed.uris
        guard !uris.isEmpty else { return }

        // Respect the free-tier limit: only import up to the remaining slots.
        let allowed: Int
        if isPro {
            allowed = uris.count
        } else {
            allowed = max(Pro.freeAccountLimit - existing.count, 0)
        }
        if allowed <= 0 {
            showPaywall = true
            return
        }

        var nextIndex = (existing.map { $0.sortIndex }.max() ?? -1) + 1
        var imported = 0
        for uri in uris.prefix(allowed) {
            let account = Account(issuer: uri.issuer,
                                  label: uri.accountName,
                                  secretBase32: uri.secretBase32,
                                  algorithm: uri.algorithm,
                                  digits: OTPGenerator.clampDigits(uri.digits),
                                  period: max(uri.period, 1),
                                  type: uri.type,
                                  counter: max(uri.counter, 0),
                                  colorHue: Double((abs(uri.issuer.hashValue) % 100)) / 100.0,
                                  sortIndex: nextIndex)
            context.insert(account)
            nextIndex += 1
            imported += 1
        }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)

        let leftover = uris.count - imported
        if leftover > 0 {
            resultMessage = "Imported \(imported). \(leftover) more need Tessera Pro (free limit reached)."
        } else {
            resultMessage = "Imported \(imported) account\(imported == 1 ? "" : "s")."
        }
        text = ""
    }
}

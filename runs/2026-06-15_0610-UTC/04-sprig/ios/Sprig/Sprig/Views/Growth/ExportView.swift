import SwiftUI

/// Pro export hub: generate a PDF pediatrician report or a CSV of measurements, then share.
/// Gated behind Pro; free users see the paywall.
struct ExportView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    let child: Child

    @State private var paywallReason: PaywallReason?
    @State private var shareURL: ShareItem?
    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !isPro {
                    lockedCard
                }
                pdfCard
                csvCard
                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.bad)
                }
                if isWorking {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Preparing export…")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                disclaimer
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Export")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        .sheet(item: $shareURL) { item in
            ShareSheet(items: [item.url])
        }
    }

    private var lockedCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Label("Sprig Pro feature", systemImage: "lock.fill")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.accent)
                Text("Exports are part of Sprig Pro. Unlock once to generate the pediatrician PDF report and CSV.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }

    private var pdfCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Pediatrician PDF report", systemImage: "doc.text.fill")
                Text("A printable one-pager: percentile charts, latest readings, and full history.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                PrimaryButton(title: isPro ? "Generate PDF" : "Unlock to generate",
                              systemImage: isPro ? "square.and.arrow.up" : "lock.fill") {
                    if isPro { generatePDF() } else { paywallReason = .pdfReport }
                }
            }
        }
    }

    private var csvCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "CSV export", systemImage: "tablecells")
                Text("Every measurement as a spreadsheet-ready CSV in your chosen units.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                PrimaryButton(title: isPro ? "Export CSV" : "Unlock to export",
                              systemImage: isPro ? "square.and.arrow.up" : "lock.fill") {
                    if isPro { generateCSV() } else { paywallReason = .csvExport }
                }
            }
        }
    }

    private var disclaimer: some View {
        Text("Exports are generated on-device. Sprig is informational only — not medical advice.")
            .font(Theme.rounded(12))
            .foregroundStyle(Theme.inkFaint)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
    }

    @MainActor
    private func generatePDF() {
        guard !child.measurements.isEmpty else {
            errorMessage = "Add at least one measurement before exporting."
            return
        }
        errorMessage = nil
        isWorking = true
        let report = GrowthReportView(child: child,
                                      mass: settings.massUnit,
                                      length: settings.lengthUnit,
                                      standard: settings.growthStandard)
        if let url = Exporter.writePDF(named: child.displayName, report: report) {
            shareURL = ShareItem(url: url)
            Haptics.success(settings.hapticsEnabled)
        } else {
            errorMessage = "Couldn't generate the PDF. Please try again."
        }
        isWorking = false
    }

    private func generateCSV() {
        guard !child.measurements.isEmpty else {
            errorMessage = "Add at least one measurement before exporting."
            return
        }
        errorMessage = nil
        isWorking = true
        if let url = Exporter.writeCSV(for: child, settings: settings) {
            shareURL = ShareItem(url: url)
            Haptics.success(settings.hapticsEnabled)
        } else {
            errorMessage = "Couldn't write the CSV. Please try again."
        }
        isWorking = false
    }
}

/// Wraps a file URL so it can drive an `.sheet(item:)`.
private struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

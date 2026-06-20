import SwiftUI
import SwiftData
import UIKit

struct InvoicePDFPreviewButton: View {
    let invoice: Invoice
    @Query private var settingsQuery: [BriefSettings]

    private var settings: BriefSettings? { settingsQuery.first }

    var body: some View {
        Button {
            sharePDF()
        } label: {
            Label("Export PDF", systemImage: "doc.fill")
        }
        .accessibilityLabel("Export invoice as PDF")
    }

    private func sharePDF() {
        let s = settings ?? BriefSettings()
        let data = InvoicePDFRenderer.generatePDF(invoice: invoice, settings: s)
        let filename = invoice.number.isEmpty ? "invoice.pdf" : "\(invoice.number).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        guard let _ = try? data.write(to: url) else { return }

        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first,
           let root = window.rootViewController {
            var presented = root
            while let next = presented.presentedViewController {
                presented = next
            }
            av.popoverPresentationController?.sourceView = window
            presented.present(av, animated: true)
        }
    }
}

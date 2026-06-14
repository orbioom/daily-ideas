import SwiftUI
import SwiftData

/// Prompts for condition and price paid when flipping a wantlist record to owned.
struct AcquireSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Bindable var record: Record

    @State private var media: Grade = .nearMint
    @State private var sleeve: Grade = .nearMint
    @State private var priceText = ""
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        CoverArtView(title: record.title, artist: record.artist, hue: record.coverHue, showDisc: false)
                            .frame(width: 54, height: 54)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.title).font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
                            Text(record.artist).font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                        }
                    }
                }
                Section("Condition") {
                    Picker("Media", selection: $media) {
                        ForEach(Grade.allCases) { g in Text(g.display).tag(g) }
                    }
                    Picker("Sleeve", selection: $sleeve) {
                        ForEach(Grade.allCases) { g in Text(g.display).tag(g) }
                    }
                }
                Section("Price paid") {
                    HStack {
                        Text(settings.currencySymbol.isEmpty ? "$" : settings.currencySymbol)
                            .foregroundStyle(Theme.inkSoft)
                        TextField("0.00", text: $priceText)
                            .keyboardType(.decimalPad)
                    }
                }
                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.bad)
                    }
                }
            }
            .navigationTitle("Mark as acquired")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Acquire") { acquire() }.fontWeight(.semibold)
                }
            }
            .onAppear {
                media = record.mediaCondition
                sleeve = record.sleeveCondition
                if record.pricePaid > 0 { priceText = String(format: "%.2f", record.pricePaid) }
            }
        }
    }

    private func parsedPrice() -> Double? {
        let trimmed = priceText.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return 0 }
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }

    private func acquire() {
        guard let price = parsedPrice(), price >= 0 else {
            validationMessage = "Enter a valid price, like 24.50, or leave it blank."
            Haptics.error(settings.hapticsEnabled)
            return
        }
        record.mediaCondition = media
        record.sleeveCondition = sleeve
        record.pricePaid = price
        record.status = .owned
        record.addedAt = .now
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}

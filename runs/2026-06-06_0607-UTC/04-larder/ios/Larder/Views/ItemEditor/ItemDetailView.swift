import SwiftUI
import SwiftData

/// Read view for a single item: status, placement, dates, quantity controls, and an
/// edit entry point. Quantity stepping is unit-aware and never drops below zero.
struct ItemDetailView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var item: Item
    @State private var showingEditor = false

    private var windowDays: Int { settings.expirySoonWindowDays }
    private var bucket: ExpiryLogic.Bucket {
        ExpiryLogic.bucket(for: item.expiryDate, windowDays: windowDays)
    }
    private var days: Int? { ExpiryLogic.daysUntil(item.expiryDate) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                quantityCard
                placementCard
                datesCard
                if !item.notes.isEmpty { notesCard }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(Brand.pageBackground)
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showingEditor = true }
                    .tint(Brand.text)
            }
        }
        .sheet(isPresented: $showingEditor) {
            ItemEditorView(item: item)
        }
    }

    private var header: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(item.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Brand.text)
                HStack(spacing: 8) {
                    if bucket != .none {
                        ExpiryBadge(bucket: bucket, daysUntil: days, showPhrase: true)
                    }
                    if item.isLowStock { LowStockBadge() }
                    if bucket == .none && !item.isLowStock {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                            Text("Stocked")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Brand.fresh)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var quantityCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "Quantity")
                HStack(spacing: 16) {
                    Button {
                        adjust(by: -1)
                    } label: {
                        Image(systemName: "minus")
                            .frame(width: 44, height: 44)
                            .background(Brand.glassStroke.opacity(0.3), in: Circle())
                    }
                    .tint(Brand.text)
                    .disabled(item.quantity <= 0)
                    .accessibilityLabel("Decrease quantity")

                    VStack(spacing: 0) {
                        Text(quantityNumber)
                            .font(Brand.mono(30, weight: .semibold))
                            .foregroundStyle(Brand.text)
                            .contentTransition(.numericText())
                        Text(item.unit.fullName)
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                    }
                    .frame(maxWidth: .infinity)

                    Button {
                        adjust(by: 1)
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 44, height: 44)
                            .background(Brand.glassStroke.opacity(0.3), in: Circle())
                    }
                    .tint(Brand.text)
                    .accessibilityLabel("Increase quantity")
                }
                Text("Low-stock at \(thresholdNumber) \(item.unit.short)")
                    .font(.footnote)
                    .foregroundStyle(Brand.text2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var placementCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "Placement")
                detailRow(label: "Location",
                          value: item.location?.name ?? "Unassigned",
                          symbol: item.location?.symbol ?? "tray")
                if let category = item.category {
                    detailRow(label: "Category", value: category.name, symbol: category.symbol,
                              tint: Brand.categoryColor(category.colorHue))
                } else {
                    detailRow(label: "Category", value: "Uncategorized", symbol: "tag")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var datesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "Dates")
                detailRow(label: "Purchased",
                          value: item.purchaseDate.map(Self.dateString) ?? "Not set",
                          symbol: "calendar")
                detailRow(label: "Expiry",
                          value: item.expiryDate.map(Self.dateString) ?? "Not set",
                          symbol: "clock")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var notesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(text: "Notes")
                Text(item.notes)
                    .font(.body)
                    .foregroundStyle(Brand.text)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func detailRow(label: String, value: String, symbol: String,
                           tint: Color = Brand.text2) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 14))
                .foregroundStyle(tint)
                .frame(width: 22)
                .accessibilityHidden(true)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Brand.text)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Helpers

    private var quantityNumber: String {
        if item.quantity == item.quantity.rounded() { return String(Int(item.quantity)) }
        return String(format: "%g", item.quantity)
    }
    private var thresholdNumber: String {
        if item.lowStockThreshold == item.lowStockThreshold.rounded() {
            return String(Int(item.lowStockThreshold))
        }
        return String(format: "%g", item.lowStockThreshold)
    }

    private static func dateString(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    private func adjust(by delta: Double) {
        let next = max(0, item.quantity + delta)
        guard next != item.quantity else { return }
        withAnimation(Brand.ease(0.25)) {
            item.quantity = next
        }
        item.updatedAt = .now
        try? context.save()
        Haptics.impact(enabled: settings.hapticsEnabled)
    }
}

#Preview {
    NavigationStack {
        ItemDetailView(item: PreviewItem.sample)
    }
    .environment(SettingsStore())
    .modelContainer(PreviewData.container)
}

/// Provides a single item from the preview container for the detail preview.
@MainActor
private enum PreviewItem {
    static var sample: Item {
        let context = PreviewData.container.mainContext
        let descriptor = FetchDescriptor<Item>()
        if let first = (try? context.fetch(descriptor))?.first {
            return first
        }
        let fallback = Item(name: "Sample", quantity: 2, unit: .piece)
        context.insert(fallback)
        return fallback
    }
}

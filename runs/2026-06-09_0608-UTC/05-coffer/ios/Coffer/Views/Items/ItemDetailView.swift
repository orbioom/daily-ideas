import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Bindable var item: Item
    @AppStorage("coffer.currencyCode") private var currencyCode = "USD"
    @AppStorage("coffer.warrantyWindowDays") private var warrantyWindowDays = 30

    @State private var showingEdit = false

    private var statusInfo: (status: WarrantyStatus, daysRemaining: Int?) {
        InventoryEngine.warrantyStatus(for: item, window: warrantyWindowDays)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                warrantyCard
                detailsCard
                if !item.notes.isEmpty { notesCard }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    Haptics.tap()
                    showingEdit = true
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            ItemEditorView(item: item, defaultRoom: item.room)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Brand.mist3.opacity(0.7))
                        .frame(width: 56, height: 56)
                    Image(systemName: item.category.symbol)
                        .font(.title2)
                        .foregroundStyle(Brand.info)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Brand.text)
                    Text(item.room?.name ?? "Unassigned")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                }
                Spacer()
            }
            HStack(spacing: 8) {
                CategoryBadge(category: item.category)
                WarrantyChip(status: statusInfo.status)
            }
            Divider().overlay(Brand.hairline)
            HStack {
                Eyebrow(text: "Value")
                Spacer()
                Text(Format.currency(item.price, code: currencyCode))
                    .font(Brand.mono(22, weight: .semibold))
                    .foregroundStyle(Brand.text)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 18)
    }

    @ViewBuilder
    private var warrantyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Warranty")
            let tint = WarrantyStyle.color(statusInfo.status)
            HStack(spacing: 10) {
                StatusDot(color: tint)
                Text(statusInfo.status.label)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(tint)
                Spacer()
            }
            switch statusInfo.status {
            case .none:
                Text("No warranty recorded for this item.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            case .active, .expiringSoon:
                if let days = statusInfo.daysRemaining, let expiry = item.warrantyExpiry {
                    detailRow("Days remaining", "\(days)", valueTint: tint)
                    detailRow("Expires", Format.date(expiry))
                }
            case .expired:
                if let expiry = item.warrantyExpiry, let days = statusInfo.daysRemaining {
                    detailRow("Expired", Format.date(expiry), valueTint: tint)
                    detailRow("Lapsed", "\(-days) days ago", valueTint: tint)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 16)
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Details")
            detailRow("Category", item.category.label)
            if !item.brand.isEmpty { detailRow("Brand", item.brand) }
            if !item.modelNumber.isEmpty { detailRow("Model", item.modelNumber) }
            if !item.serial.isEmpty { detailRow("Serial", item.serial) }
            detailRow("Purchased", Format.date(item.purchaseDate))
            if item.warrantyMonths > 0 {
                detailRow("Warranty length", "\(item.warrantyMonths) month\(item.warrantyMonths == 1 ? "" : "s")")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 16)
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Notes")
            Text(item.notes)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 16)
    }

    private func detailRow(_ label: String, _ value: String, valueTint: Color = Brand.text) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Brand.text3)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(valueTint)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }
}

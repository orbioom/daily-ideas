import SwiftUI
import SwiftData

struct SpoolDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("currencySymbol") private var currency = "$"
    @Bindable var spool: Spool
    @State private var showEdit = false
    @State private var confirmDelete = false
    @State private var adjustGrams = ""
    @State private var showAdjust = false

    private var jobs: [PrintJob] { spool.prints.sorted { $0.date > $1.date } }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                HStack(spacing: 12) {
                    StatTile(value: "\(Int(spool.remainingG)) g", label: "Remaining",
                             accent: spool.isLow ? Brand.danger : Brand.text)
                    StatTile(value: String(format: "%.0f m", spool.lengthRemainingM), label: "Length left",
                             accent: Brand.info)
                }
                HStack(spacing: 12) {
                    StatTile(value: "\(Int(spool.fractionRemaining * 100))%", label: "Of full")
                    StatTile(value: Money.string(spool.pricePerGram * 1000, symbol: currency), label: "Per kg",
                             accent: Brand.text2)
                }

                Button {
                    Haptics.tap(); showAdjust = true
                } label: {
                    Label("Log usage / correct weight", systemImage: "slider.horizontal.3")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())

                if !spool.notes.isEmpty {
                    Text(spool.notes).font(.subheadline).foregroundStyle(Brand.text2)
                        .frame(maxWidth: .infinity, alignment: .leading).glassCard()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(text: "Material")
                    detailRow("Type", spool.material.rawValue)
                    detailRow("Density", String(format: "%.2f g/cm³", spool.material.density))
                    detailRow("Print temp", spool.material.tempRange)
                    detailRow("Diameter", spool.diameter.label)
                }
                .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)

                SectionHeader(title: "Used in \(jobs.count) print\(jobs.count == 1 ? "" : "s")")
                if jobs.isEmpty {
                    Text("No prints logged from this spool yet.")
                        .font(.subheadline).foregroundStyle(Brand.text2)
                        .frame(maxWidth: .infinity, alignment: .leading).glassCard()
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(jobs) { j in
                            HStack {
                                Image(systemName: j.success ? "checkmark.circle" : "xmark.circle")
                                    .foregroundStyle(j.success ? Brand.live : Brand.danger)
                                    .accessibilityHidden(true)
                                Text(j.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                                Spacer()
                                Text("\(Int(j.gramsUsed)) g").font(Brand.mono(13)).foregroundStyle(Brand.text2)
                                Text(j.date, format: .dateTime.month().day())
                                    .font(Brand.mono(12)).foregroundStyle(Brand.text3)
                            }
                            .glassCard(padding: 12)
                        }
                    }
                }

                Button(role: .destructive) { confirmDelete = true } label: {
                    Label("Delete spool", systemImage: "trash").frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle()).tint(Brand.danger)
            }
            .padding(16)
        }
        .background(Brand.pageBackground)
        .navigationTitle(spool.colorName).navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Edit") { showEdit = true } } }
        .sheet(isPresented: $showEdit) { SpoolEditView(spool: spool) }
        .alert("Adjust remaining filament", isPresented: $showAdjust) {
            TextField("Grams to subtract", text: $adjustGrams).keyboardType(.numberPad)
            Button("Subtract") { applyAdjust() }
            Button("Cancel", role: .cancel) { adjustGrams = "" }
        } message: {
            Text("Enter grams used since the last update. Remaining is currently \(Int(spool.remainingG)) g.")
        }
        .alert("Delete this spool?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                context.delete(spool); try? context.save(); Haptics.warning(); dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Linked prints are kept but lose their spool reference.") }
    }

    private var header: some View {
        HStack(spacing: 14) {
            ColorSwatch(hex: spool.colorHex, size: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(spool.brand).font(.title3.weight(.bold)).foregroundStyle(Brand.text)
                HStack(spacing: 6) { Chip(text: spool.material.rawValue); Chip(text: spool.diameter.label) }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)
    }

    private func detailRow(_ l: String, _ v: String) -> some View {
        HStack { Text(l).font(.subheadline).foregroundStyle(Brand.text3); Spacer()
            Text(v).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text) }
    }

    private func applyAdjust() {
        guard let g = Double(adjustGrams), g > 0 else { adjustGrams = ""; return }
        spool.remainingG = max(0, spool.remainingG - g)
        try? context.save(); Haptics.success(); adjustGrams = ""
    }
}

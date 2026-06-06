import SwiftUI
import SwiftData

struct PrintDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("currencySymbol") private var currency = "$"
    @AppStorage("kwhRate") private var kwhRate = 0.15
    @Bindable var job: PrintJob
    @State private var showEdit = false
    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(job.name).font(.title2.weight(.bold)).foregroundStyle(Brand.text)
                        Spacer()
                        Label(job.success ? "Success" : "Failed",
                              systemImage: job.success ? "checkmark.seal.fill" : "xmark.seal.fill")
                            .font(.subheadline).foregroundStyle(job.success ? Brand.live : Brand.danger)
                    }
                    Text(job.date, format: .dateTime.weekday().month().day().hour().minute())
                        .font(Brand.mono(13)).foregroundStyle(Brand.text2)
                }
                .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)

                HStack(spacing: 12) {
                    StatTile(value: "\(Int(job.gramsUsed)) g", label: "Filament")
                    StatTile(value: durationLabel, label: "Time")
                }
                HStack(spacing: 12) {
                    StatTile(value: Money.string(job.filamentCost, symbol: currency), label: "Filament cost")
                    StatTile(value: Money.string(job.electricityCost(kwhRate: kwhRate), symbol: currency),
                             label: "Electricity", accent: Brand.info)
                }
                VStack(spacing: 6) {
                    Text("Total cost").font(Brand.mono(11, weight: .medium)).tracking(1).foregroundStyle(Brand.text3)
                    Text(Money.string(job.totalCost(kwhRate: kwhRate), symbol: currency))
                        .font(Brand.mono(34, weight: .bold)).foregroundStyle(Brand.text)
                }
                .frame(maxWidth: .infinity).glassCard(padding: 20)

                VStack(alignment: .leading, spacing: 8) {
                    if let s = job.spool {
                        HStack { Text("Spool").font(.subheadline).foregroundStyle(Brand.text3); Spacer()
                            HStack(spacing: 6) { ColorSwatch(hex: s.colorHex, size: 18)
                                Text(s.displayName).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text) } }
                    }
                    if let p = job.printer {
                        HStack { Text("Printer").font(.subheadline).foregroundStyle(Brand.text3); Spacer()
                            Text(p.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text) }
                    }
                    if !job.notes.isEmpty {
                        Divider().overlay(Brand.hairline)
                        Text(job.notes).font(.subheadline).foregroundStyle(Brand.text2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)

                Button(role: .destructive) { confirmDelete = true } label: {
                    Label("Delete print", systemImage: "trash").frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle()).tint(Brand.danger)
            }
            .padding(16)
        }
        .background(Brand.pageBackground)
        .navigationTitle("Print").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Edit") { showEdit = true } } }
        .sheet(isPresented: $showEdit) { PrintEditView(job: job) }
        .alert("Delete this print?", isPresented: $confirmDelete) {
            Button("Delete & restore filament", role: .destructive) {
                if let s = job.spool { s.remainingG = min(s.netWeightG, s.remainingG + job.gramsUsed) }
                context.delete(job); try? context.save(); Haptics.warning(); dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("The \(Int(job.gramsUsed)) g used will be credited back to its spool.") }
    }

    private var durationLabel: String {
        let h = job.durationMinutes / 60, m = job.durationMinutes % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}

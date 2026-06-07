import SwiftUI
import SwiftData

struct MedDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var med: Medication
    @State private var showingEdit = false
    @State private var showingRefill = false

    private var logs: [DoseLog] { med.logs.sorted { $0.scheduledAt > $1.scheduledAt } }
    private var adherence: Double {
        DoseEngine.adherence(for: [med], logs: med.logs, trailingDays: 30)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                supplyCard
                scheduleCard
                adherenceCard
                historyCard
                if !med.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionTitle(text: "Notes")
                        Text(med.notes).font(.subheadline).foregroundStyle(Brand.text2)
                    }.glassCard()
                }
            }
            .padding()
        }
        .navigationTitle(med.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Brand.pageBackground)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingRefill = true } label: { Label("Log refill", systemImage: "plus.circle") }
                    Button { showingEdit = true } label: { Label("Edit", systemImage: "pencil") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showingEdit) { MedEditView(existing: med) }
        .sheet(isPresented: $showingRefill) { RefillEditView(med: med) }
    }

    private var supplyCard: some View {
        VStack(spacing: 10) {
            Text("\(Int(med.quantityOnHand))")
                .font(Brand.mono(44, weight: .bold)).foregroundStyle(Brand.text)
            Text("\(med.form.lowercased())s on hand").font(.caption).foregroundStyle(Brand.text3)
            let cols = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: cols, spacing: 10) {
                StatTile(value: med.daysOfSupply.isInfinite ? "—" : "\(Int(med.daysOfSupply.rounded(.down)))d",
                         label: "Days of supply",
                         accent: DoseEngine.needsRefillSoon(med) ? Brand.warn : Brand.text)
                if let runOut = DoseEngine.runOutDate(for: med) {
                    StatTile(value: runOut.formatted(.dateTime.month(.abbreviated).day()), label: "Runs out")
                } else {
                    StatTile(value: "—", label: "Runs out")
                }
            }
            if let refillBy = DoseEngine.refillByDate(for: med) {
                Text("Order a refill by \(refillBy.formatted(.dateTime.weekday(.wide).month().day()))")
                    .font(.caption).foregroundStyle(DoseEngine.needsRefillSoon(med) ? Brand.warn : Brand.text2)
            }
            Button { Haptics.tap(); showingRefill = true } label: {
                Label("Log a refill", systemImage: "shippingbox").frame(maxWidth: .infinity)
            }.buttonStyle(GlassButtonStyle())
        }
        .frame(maxWidth: .infinity).padding(.vertical, 18).glassCard()
    }

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Schedule")
            InfoRow(label: "Strength", value: med.strength.isEmpty ? "—" : med.strength)
            Divider().overlay(Brand.hairline)
            InfoRow(label: "Per dose",
                    value: "\(med.unitsPerDose == med.unitsPerDose.rounded() ? "\(Int(med.unitsPerDose))" : String(format: "%.1f", med.unitsPerDose)) \(med.form.lowercased())")
            Divider().overlay(Brand.hairline)
            HStack {
                Text("Times").foregroundStyle(Brand.text2)
                Spacer()
                Text(med.sortedDoseTimes.map { DoseEngine.formatMinutes($0) }.joined(separator: ", "))
                    .font(.subheadline).foregroundStyle(Brand.text).multilineTextAlignment(.trailing)
            }
            .font(.subheadline)
            Divider().overlay(Brand.hairline)
            InfoRow(label: "Days", value: med.weekdays.isEmpty ? "Every day" :
                        med.weekdays.sorted().map { DoseEngine.weekdayNames[$0] }.joined(separator: " "))
        }
        .glassCard()
    }

    private var adherenceCard: some View {
        let (taken, scheduled) = DoseEngine.adherenceCounts(for: [med], logs: med.logs, trailingDays: 30)
        return VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "30-day adherence")
            HStack {
                Text("\(Int((adherence * 100).rounded()))%")
                    .font(Brand.mono(28, weight: .bold)).foregroundStyle(Brand.live)
                Spacer()
                Text("\(taken) of \(scheduled) doses").font(.subheadline).foregroundStyle(Brand.text2)
            }
            MeterBar(fraction: adherence, color: Brand.live)
        }
        .glassCard()
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Recent doses")
            if logs.isEmpty {
                Text("No doses logged yet.").font(.caption).foregroundStyle(Brand.text3)
            } else {
                ForEach(logs.prefix(12)) { log in
                    HStack {
                        Image(systemName: log.status == "taken" ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundStyle(log.status == "taken" ? Brand.live : Brand.text3)
                        Text(log.scheduledAt.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute()))
                            .font(.caption).foregroundStyle(Brand.text2)
                        Spacer()
                        Text(log.status.capitalized).font(Brand.mono(11)).foregroundStyle(Brand.text3)
                    }
                    if log.id != logs.prefix(12).last?.id { Divider().overlay(Brand.hairline) }
                }
            }
        }
        .glassCard()
    }
}

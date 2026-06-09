import SwiftUI
import SwiftData

struct EntryDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: VitalEntry

    @AppStorage("cuff.weightUnit") private var weightUnitRaw = WeightUnit.kg.rawValue
    @AppStorage("cuff.glucoseUnit") private var glucoseUnitRaw = GlucoseUnit.mgdl.rawValue

    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    private var weightUnit: WeightUnit { WeightUnit.from(weightUnitRaw) }
    private var glucoseUnit: GlucoseUnit { GlucoseUnit.from(glucoseUnitRaw) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                headerCard
                if entry.kind == .bloodPressure { bpDetailCard }
                detailsCard
                if !entry.note.isEmpty { noteCard }
            }
            .padding(20)
        }
        .background(Brand.pageBackground)
        .navigationTitle(entry.kind.shortLabel)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) { AddEntryView(editing: entry) }
        .safeAreaInset(edge: .bottom) {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete reading", systemImage: "trash")
            }
            .buttonStyle(GlassButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .confirmationDialog("Delete this reading?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { delete() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var headerCard: some View {
        VStack(spacing: 10) {
            Image(systemName: entry.kind.symbol)
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(entry.kind.tint)
                .accessibilityHidden(true)
            if entry.kind == .bloodPressure {
                Text("\(entry.systolic)/\(entry.diastolic)")
                    .font(Brand.mono(40, weight: .bold)).foregroundStyle(Brand.text)
                Text("mmHg").font(Brand.mono(13)).foregroundStyle(Brand.text2)
                BPCategoryBadge(category: entry.category)
            } else {
                Text(Format.value(entry, weight: weightUnit, glucose: glucoseUnit))
                    .font(Brand.mono(40, weight: .bold)).foregroundStyle(Brand.text)
                Text(entry.kind.label).font(Brand.mono(13)).foregroundStyle(Brand.text2)
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 20)
        .accessibilityElement(children: .combine)
    }

    private var bpDetailCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Reading")
            detailRow("Systolic", "\(entry.systolic) mmHg")
            detailRow("Diastolic", "\(entry.diastolic) mmHg")
            if entry.pulse > 0 { detailRow("Pulse", "\(entry.pulse) bpm") }
            detailRow("Mean arterial (MAP)", "\(entry.meanArterialPressure) mmHg")
            detailRow("Pulse pressure", "\(entry.pulsePressure) mmHg")
            detailRow("Arm", entry.arm.label)
            HStack {
                Text("AHA category").foregroundStyle(Brand.text2)
                Spacer()
                Text(entry.category.rangeDescription).font(Brand.mono(12)).foregroundStyle(Brand.text3)
            }
        }
        .glassCard()
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Details")
            detailRow("Date", Format.dayFormatter.string(from: entry.date))
            detailRow("Time", Format.time.string(from: entry.date))
            detailRow("Time of day", entry.tag.label)
        }
        .glassCard()
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Note")
            Text(entry.note).font(.body).foregroundStyle(Brand.text2)
        }
        .glassCard()
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Brand.text2)
            Spacer()
            Text(value).font(Brand.mono(14, weight: .medium)).foregroundStyle(Brand.text)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private func delete() {
        context.delete(entry)
        try? context.save()
        Haptics.warning()
        dismiss()
    }
}

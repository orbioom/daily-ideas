import SwiftUI
import SwiftData

struct AttackDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var attack: Attack

    @State private var showEditor = false
    @State private var showDeleteConfirm = false

    private var durationText: String {
        if attack.isOngoing { return "Ongoing" }
        if let m = attack.durationMinutes { return Format.duration(minutes: m) }
        return "—"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                detailGrid
                if !attack.triggers.isEmpty { triggersCard }
                if !attack.symptoms.isEmpty { symptomsCard }
                if !attack.meds.isEmpty { medsCard }
                if !attack.note.isEmpty { noteCard }
                deleteButton
            }
            .padding(20)
        }
        .background(Brand.pageBackground)
        .navigationTitle("Attack")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showEditor = true }
            }
        }
        .sheet(isPresented: $showEditor) {
            AttackEditorView(existing: attack)
        }
        .confirmationDialog("Delete this attack?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { delete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes the entry and its medication records.")
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Label(attack.type.label, systemImage: attack.type.symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Brand.text)
            HStack(spacing: 6) {
                Circle().fill(IntensityScale.color(attack.intensity)).frame(width: 14, height: 14)
                Text("Intensity \(attack.intensity) of 10 · \(IntensityScale.label(attack.intensity))")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Intensity \(attack.intensity) of 10, \(IntensityScale.label(attack.intensity))")
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 20)
    }

    private var detailGrid: some View {
        VStack(spacing: 0) {
            detailRow("Started", Format.dayTime.string(from: attack.start))
            Divider().overlay(Brand.hairline)
            detailRow("Ended", attack.end.map { Format.dayTime.string(from: $0) } ?? "Ongoing")
            Divider().overlay(Brand.hairline)
            detailRow("Duration", durationText)
            Divider().overlay(Brand.hairline)
            detailRow("Location", attack.location.label)
            Divider().overlay(Brand.hairline)
            detailRow("Visual aura", attack.auraPresent ? "Yes" : "No")
        }
        .glassCard(padding: 4)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Brand.text2)
            Spacer()
            Text(value).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }

    private var triggersCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Triggers")
            FlowLayout(spacing: 8) {
                ForEach(attack.triggers.sorted(by: { $0.name < $1.name }), id: \.persistentModelID) { t in
                    TagChip(text: t.name, systemImage: t.category.symbol, tint: Brand.info)
                }
            }
        }
        .glassCard()
    }

    private var symptomsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Symptoms")
            FlowLayout(spacing: 8) {
                ForEach(attack.symptoms.sorted(by: { $0.name < $1.name }), id: \.persistentModelID) { s in
                    TagChip(text: s.name, tint: Brand.magic)
                }
            }
        }
        .glassCard()
    }

    private var medsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Medications")
            ForEach(attack.meds.sorted(by: { $0.minutesAfterOnset < $1.minutesAfterOnset }), id: \.persistentModelID) { med in
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(med.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                        Spacer()
                        Text(Format.dose(med.doseMg)).font(Brand.mono(13)).foregroundStyle(Brand.text2)
                    }
                    HStack(spacing: 6) {
                        Text("\(med.minutesAfterOnset) min after onset")
                            .font(.caption).foregroundStyle(Brand.text3)
                        Spacer()
                        TagChip(text: med.relief.label, tint: med.relief.tint)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(med.name), \(Format.dose(med.doseMg)), \(med.minutesAfterOnset) minutes after onset, \(med.relief.label)")
            }
        }
        .glassCard()
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Note")
            Text(attack.note)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
        }
        .glassCard()
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            Label("Delete attack", systemImage: "trash")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(GlassButtonStyle())
        .tint(Brand.danger)
    }

    private func delete() {
        context.delete(attack)
        try? context.save()
        Haptics.warning()
        dismiss()
    }
}

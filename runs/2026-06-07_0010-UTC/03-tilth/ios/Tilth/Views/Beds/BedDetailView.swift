import SwiftUI
import SwiftData

struct BedDetailView: View {
    @Bindable var bed: Bed
    @Environment(\.modelContext) private var context
    @State private var showingEdit = false

    private var sortedPlantings: [Planting] {
        bed.plantings.sorted { $0.sowDate < $1.sowDate }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(spacing: 16) {
                    header
                    plantingsSection
                }
                .padding(.horizontal, 18).padding(.vertical, 12)
            }
        }
        .navigationTitle(bed.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingEdit = true } label: { Image(systemName: "pencil") }
                    .accessibilityLabel("Edit bed")
            }
        }
        .sheet(isPresented: $showingEdit) { BedEditView(bed: bed) }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatTile(value: String(format: "%.0f", bed.areaSqFt), label: "sq ft")
                StatTile(value: "\(bed.sunHours)h", label: "sun", accent: Brand.warn)
                StatTile(value: "\(bed.activePlantings.count)", label: "growing", accent: Brand.live)
            }
            if !bed.notes.isEmpty {
                Text(bed.notes).font(.footnote).foregroundStyle(Brand.text2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var plantingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "What's planted", trailing: "\(bed.plantings.count)")
            if bed.plantings.isEmpty {
                Text("Nothing here yet. Add a planting from the Plan tab and assign it to this bed.")
                    .font(.subheadline).foregroundStyle(Brand.text2)
                    .frame(maxWidth: .infinity).glassCard(padding: 18)
            } else {
                ForEach(sortedPlantings) { p in
                    HStack {
                        Image(systemName: p.category.symbol).foregroundStyle(Brand.text2)
                            .frame(width: 24).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.cropName).font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
                            Text("sow \(Fmt.date(p.sowDate)) · ×\(p.quantity)")
                                .font(.caption).foregroundStyle(Brand.text3)
                        }
                        Spacer()
                        Chip(text: p.status.label, tint: p.status.tint)
                    }
                    .glassCard(padding: 12)
                    .swipeActions {
                        Button(role: .destructive) {
                            bed.plantings.removeAll { $0.id == p.id }
                            context.delete(p); try? context.save()
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
    }
}

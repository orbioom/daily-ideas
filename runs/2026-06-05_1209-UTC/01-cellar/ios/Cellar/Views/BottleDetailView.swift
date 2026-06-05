import SwiftUI
import SwiftData

/// A single bottle: its metadata, every tasting recorded against it, and the actions
/// to taste again, edit, or delete.
struct BottleDetailView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let bottle: Bottle

    @State private var showingEdit = false
    @State private var showingTasting = false
    @State private var editingTasting: Tasting?
    @State private var showingDeleteBottle = false
    @State private var tastingToDelete: Tasting?

    private var sortedTastings: [Tasting] {
        bottle.tastings.sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                if !bottle.notes.isEmpty { notesCard }
                tastingsSection
            }
            .padding(16)
        }
        .background(Brand.pageBackground)
        .navigationTitle(bottle.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingEdit = true } label: { Label("Edit bottle", systemImage: "pencil") }
                    Button(role: .destructive) { showingDeleteBottle = true } label: {
                        Label("Delete bottle", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle").accessibilityLabel("Bottle options")
                }
            }
        }
        .sheet(isPresented: $showingEdit) { BottleEditView(bottle: bottle) }
        .sheet(isPresented: $showingTasting) {
            TastingEditView(bottle: bottle, tasting: nil)
        }
        .sheet(item: $editingTasting) { tasting in
            TastingEditView(bottle: bottle, tasting: tasting)
        }
        .alert("Delete this bottle?", isPresented: $showingDeleteBottle) {
            Button("Delete", role: .destructive) { deleteBottle() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This also removes its \(bottle.tastingCount) tasting\(bottle.tastingCount == 1 ? "" : "s"). This can't be undone.")
        }
        .alert("Delete this tasting?", isPresented: Binding(
            get: { tastingToDelete != nil },
            set: { if !$0 { tastingToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let t = tastingToDelete { deleteTasting(t) }
            }
            Button("Cancel", role: .cancel) { tastingToDelete = nil }
        }
    }

    // MARK: - Header

    private var header: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(hex: UInt32(truncatingIfNeeded: bottle.colorHex)))
                        .frame(width: 10, height: 54)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bottle.name).font(.title2.weight(.bold)).foregroundStyle(Brand.text)
                        if !bottle.producer.isEmpty {
                            Text(bottle.producer).font(.subheadline).foregroundStyle(Brand.text2)
                        }
                    }
                    Spacer()
                    CategoryBadge(category: bottle.category)
                }

                Divider().overlay(Brand.glassStroke.opacity(0.4))

                metaRow(label: bottle.category.originLabel, value: bottle.origin.isEmpty ? "—" : bottle.origin)
                if let year = bottle.year {
                    metaRow(label: bottle.category.yearLabel, value: String(year), mono: true)
                }
                if let avg = bottle.averageRating {
                    HStack {
                        Text("Average").font(.subheadline).foregroundStyle(Brand.text3)
                        Spacer()
                        RatingDisplay(value: avg, size: 14)
                        Text(String(format: "%.1f", avg))
                            .font(Brand.mono(14, weight: .semibold)).foregroundStyle(Brand.text)
                    }
                }
            }
        }
    }

    private func metaRow(label: String, value: String, mono: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(.subheadline).foregroundStyle(Brand.text3)
            Spacer()
            Text(value)
                .font(mono ? Brand.mono(15) : .subheadline)
                .foregroundStyle(Brand.text)
                .multilineTextAlignment(.trailing)
        }
    }

    private var notesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("Notes").font(.caption.weight(.semibold)).foregroundStyle(Brand.text3)
                Text(bottle.notes).font(.body).foregroundStyle(Brand.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Tastings

    private var tastingsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Tastings").font(.headline).foregroundStyle(Brand.text)
                Spacer()
                Text("\(bottle.tastingCount)")
                    .font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.text2)
            }

            if sortedTastings.isEmpty {
                GlassCard {
                    VStack(spacing: 8) {
                        Image(systemName: "drop").font(.title2).foregroundStyle(Brand.text3)
                        Text("Not tasted yet")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
                        Text("Record your first impression while it's fresh.")
                            .font(.footnote).foregroundStyle(Brand.text2)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            } else {
                ForEach(sortedTastings) { tasting in
                    Button {
                        editingTasting = tasting
                    } label: {
                        TastingCardContent(tasting: tasting)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button { editingTasting = tasting } label: { Label("Edit", systemImage: "pencil") }
                        Button(role: .destructive) { tastingToDelete = tasting } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .accessibilityHint("Opens this tasting to edit")
                }
            }

            InkButton(title: "Record a tasting", systemImage: "plus") {
                showingTasting = true
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Mutations

    private func deleteBottle() {
        Haptics.warning(enabled: settings.hapticsEnabled)
        context.delete(bottle)
        dismiss()
    }

    private func deleteTasting(_ tasting: Tasting) {
        Haptics.warning(enabled: settings.hapticsEnabled)
        withAnimation(Brand.ease()) { context.delete(tasting) }
        tastingToDelete = nil
    }
}

/// One tasting rendered as a glass card.
private struct TastingCardContent: View {
    let tasting: Tasting

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    RatingDisplay(value: Double(tasting.rating), size: 14)
                    Spacer()
                    Text(tasting.date, format: .dateTime.day().month().year())
                        .font(Brand.mono(12)).foregroundStyle(Brand.text3)
                }
                if !tasting.flavorTags.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(tasting.flavorTags, id: \.self) { tag in
                            FlavorChip(label: tag, selected: false)
                        }
                    }
                }
                triad
                if !tasting.overallNote.isEmpty {
                    Text(tasting.overallNote)
                        .font(.subheadline).foregroundStyle(Brand.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var triad: some View {
        let rows: [(String, String)] = [
            ("Aroma", tasting.aroma),
            ("Palate", tasting.palate),
            ("Finish", tasting.finish)
        ].filter { !$0.1.isEmpty }
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 5) {
                ForEach(rows, id: \.0) { row in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(row.0)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Brand.text3)
                            .frame(width: 52, alignment: .leading)
                        Text(row.1).font(.footnote).foregroundStyle(Brand.text2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

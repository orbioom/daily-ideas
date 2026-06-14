import SwiftUI
import SwiftData

/// Full detail: juice hero, note pyramid, season/occasion, meters, cost-per-wear, wear log.
struct FragranceDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Bindable var fragrance: Fragrance

    @State private var showEdit = false
    @State private var showAddWear = false
    @State private var editingWear: WearLog?
    @State private var showDeleteConfirm = false
    @State private var justLogged = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                hero
                metaRow
                wearButton
                statRow
                if !fragrance.placements.isEmpty { pyramidCard }
                if !fragrance.seasons.isEmpty || !fragrance.occasions.isEmpty { whenCard }
                meterCard
                if !fragrance.notes.isEmpty { notesCard }
                wearLogSection
                deleteButton
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(fragrance.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showEdit = true } label: { Image(systemName: "pencil") }
                    .accessibilityLabel("Edit fragrance")
            }
        }
        .sheet(isPresented: $showEdit) {
            FragranceEditorView(existing: fragrance)
        }
        .sheet(isPresented: $showAddWear) {
            WearLogEditorView(fragrance: fragrance)
        }
        .sheet(item: $editingWear) { wear in
            WearLogEditorView(fragrance: fragrance, existing: wear)
        }
        .confirmationDialog("Delete \(fragrance.name)?",
                            isPresented: $showDeleteConfirm,
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) { performDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the fragrance and its wear log. This can't be undone.")
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(spacing: 12) {
            JuiceSwatch(family: fragrance.primaryFamily, colorHue: fragrance.colorHue, size: 132)
            VStack(spacing: 4) {
                Text(fragrance.house.uppercased())
                    .font(Theme.rounded(12, .bold))
                    .foregroundStyle(Theme.inkFaint)
                Text(fragrance.name)
                    .font(Theme.serif(26, .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
            }
            if fragrance.rating > 0 {
                RatingStars(rating: fragrance.rating, size: 14)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private var metaRow: some View {
        FlowLayout(spacing: 8) {
            Pill(text: fragrance.concentration.rawValue, systemImage: "drop", tint: Theme.accent)
            Pill(text: fragrance.status.rawValue, systemImage: fragrance.status.symbol, tint: fragrance.status.tint)
            Pill(text: "\(trimmed(fragrance.sizeML)) mL", systemImage: "drop")
            if !settings.hidePrices && fragrance.pricePaid > 0 {
                Pill(text: settings.formatMoney(fragrance.pricePaid), systemImage: "creditcard")
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var wearButton: some View {
        VStack(spacing: 8) {
            PrimaryButton(title: justLogged ? "Logged!" : "I wore this today",
                          systemImage: justLogged ? "checkmark.circle.fill" : "checkmark.seal") {
                logWearToday()
            }
            Button {
                showAddWear = true
            } label: {
                Text("Log a different day")
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }

    private var statRow: some View {
        HStack(spacing: 10) {
            statTile("Worn", "\(fragrance.timesWorn)", "flame")
            statTile("Last", lastWornLabel, "clock")
            statTile("Per wear", costPerWearLabel, "dollarsign.circle")
        }
    }

    private func statTile(_ title: String, _ value: String, _ symbol: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(value)
                .font(Theme.rounded(17, .bold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(Theme.rounded(11))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: Pyramid

    private var pyramidCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardTitle("Note pyramid", symbol: "triangle")
            ForEach(NoteSlot.allCases) { slot in
                let placements = fragrance.orderedNotes(in: slot)
                if !placements.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(slot.rawValue.uppercased())
                            .font(Theme.rounded(11, .bold))
                            .foregroundStyle(Theme.inkFaint)
                        Text(slot.subtitle)
                            .font(Theme.rounded(11))
                            .foregroundStyle(Theme.inkFaint)
                        FlowLayout(spacing: 6) {
                            ForEach(placements) { p in
                                NoteChip(name: p.displayName, family: p.family)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
    }

    private var whenCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle("When to wear", symbol: "calendar")
            if !fragrance.seasons.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(Array(fragrance.seasons).sorted { $0.rawValue < $1.rawValue }) { s in
                        Pill(text: s.rawValue, systemImage: s.symbol, tint: s.hue)
                    }
                }
            }
            if !fragrance.occasions.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(Array(fragrance.occasions).sorted { $0.rawValue < $1.rawValue }) { o in
                        Pill(text: o.rawValue, systemImage: o.symbol, tint: Theme.accent)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
    }

    private var meterCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardTitle("Performance", symbol: "gauge")
            MeterBar(title: "Longevity", symbol: "hourglass", value: fragrance.longevityRating)
            MeterBar(title: "Sillage", symbol: "wind", value: fragrance.sillageRating)
            if settings.showLongevityHints {
                Text("\(fragrance.concentration.fullName) · typical wear \(fragrance.concentration.longevityHint)")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            cardTitle("Your notes", symbol: "text.quote")
            Text(fragrance.notes)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
    }

    // MARK: Wear log

    private var wearLogSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                cardTitle("Wear log", symbol: "list.bullet.rectangle")
                Spacer()
                Button {
                    showAddWear = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityLabel("Add a wear")
            }
            if fragrance.wears.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "moon.zzz").foregroundStyle(Theme.inkFaint)
                    Text("No wears logged yet. Tap “I wore this today” to start.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                    Spacer()
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surfaceAlt))
            } else {
                ForEach(fragrance.wears.sorted { $0.date > $1.date }) { wear in
                    Button { editingWear = wear } label: { wearRow(wear) }
                        .buttonStyle(.plain)
                }
            }
        }
    }

    private func wearRow(_ wear: WearLog) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(wear.date.formatted(date: .abbreviated, time: .omitted))
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 6) {
                    if let s = wear.season { Text(s.rawValue) }
                    if wear.season != nil && wear.occasion != nil { Text("·") }
                    if let o = wear.occasion { Text(o.rawValue) }
                    if !wear.note.isEmpty {
                        Text("· \(wear.note)").lineLimit(1)
                    }
                }
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(Theme.inkFaint)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface))
        .swipeActions {
            Button(role: .destructive) {
                deleteWear(wear)
            } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            Label("Delete fragrance", systemImage: "trash")
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.bad)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.bad.opacity(0.1)))
        }
        .padding(.top, 8)
    }

    // MARK: Helpers

    private func cardTitle(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(Theme.serif(18, .semibold))
            .foregroundStyle(Theme.ink)
    }

    private var lastWornLabel: String {
        guard let last = fragrance.lastWorn else { return "Never" }
        let days = Calendar.current.dateComponents([.day], from: last, to: .now).day ?? 0
        if days <= 0 { return "Today" }
        if days == 1 { return "1d ago" }
        return "\(days)d ago"
    }

    private var costPerWearLabel: String {
        if settings.hidePrices { return "•••" }
        if fragrance.pricePaid <= 0 { return "—" }
        return settings.formatMoney(fragrance.costPerWear)
    }

    private func trimmed(_ value: Double) -> String {
        if value == value.rounded() { return String(Int(value)) }
        return String(format: "%.1f", value)
    }

    private func logWearToday() {
        let log = WearLog(date: .now,
                          occasion: fragrance.occasions.first,
                          season: Season.current(),
                          note: "")
        log.fragrance = fragrance
        fragrance.wears.append(log)
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        withAnimation { justLogged = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation { justLogged = false }
        }
    }

    private func deleteWear(_ wear: WearLog) {
        context.delete(wear)
        try? context.save()
        Haptics.tap(settings.hapticsEnabled)
    }

    private func performDelete() {
        context.delete(fragrance)
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}

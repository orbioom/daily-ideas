import SwiftUI
import SwiftData

/// Add or edit a fragrance, including its note pyramid. Validates name & house.
struct FragranceEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings

    /// When nil, this is an add flow; otherwise an edit of the given fragrance.
    var existing: Fragrance?
    /// Status to default to for new items (e.g. .wishlist from the Wishlist tab).
    var defaultStatus: BottleStatus = .owned

    // Draft fields
    @State private var name = ""
    @State private var house = ""
    @State private var concentration: Concentration = .edp
    @State private var status: BottleStatus = .owned
    @State private var sizeText = "50"
    @State private var priceText = ""
    @State private var bottlesText = "1"
    @State private var rating = 0
    @State private var longevity = 3
    @State private var sillage = 3
    @State private var colorHue = 0.12
    @State private var seasons: Set<Season> = []
    @State private var occasions: Set<Occasion> = []
    @State private var noteText = ""

    // Pyramid drafts (ordered names per slot)
    @State private var topNotes: [String] = []
    @State private var heartNotes: [String] = []
    @State private var baseNotes: [String] = []
    /// Family lookup by note name, built from current store + picker selections.
    @State private var familyByName: [String: NoteFamily] = [:]

    @State private var validationMessage: String?
    @State private var pickerSlot: NoteSlot?
    @State private var didLoad = false

    var body: some View {
        NavigationStack {
            Form {
                identitySection
                statusSection
                pyramidSection
                seasonOccasionSection
                ratingsSection
                detailsSection
                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.bad)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(existing == nil ? "Add Fragrance" : "Edit Fragrance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.font(Theme.rounded(17, .semibold))
                }
            }
            .sheet(item: $pickerSlot) { slot in
                NotePickerView(slot: slot,
                               selectedNames: Set(names(for: slot)),
                               onToggle: { toggle($0, in: slot) })
            }
            .onAppear(perform: loadIfNeeded)
        }
    }

    // MARK: Sections

    private var identitySection: some View {
        Section {
            TextField("Name (e.g. Aventus)", text: $name)
                .font(Theme.rounded(17))
            TextField("House (e.g. Creed)", text: $house)
                .font(Theme.rounded(17))
            Picker("Concentration", selection: $concentration) {
                ForEach(Concentration.allCases) { c in
                    Text("\(c.rawValue) — \(c.fullName)").tag(c)
                }
            }
        } header: {
            Text("Identity")
        } footer: {
            if settings.showLongevityHints {
                Text("\(concentration.fullName) · typical wear \(concentration.longevityHint)")
            }
        }
    }

    private var statusSection: some View {
        Section {
            Picker("Status", selection: $status) {
                ForEach(BottleStatus.allCases) { s in
                    Label(s.rawValue, systemImage: s.symbol).tag(s)
                }
            }
            HStack {
                Text("Size (mL)")
                Spacer()
                TextField("50", text: $sizeText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
            HStack {
                Text("Price paid")
                Spacer()
                Text(settings.priceCurrencySymbol).foregroundStyle(Theme.inkSoft)
                TextField("0", text: $priceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
            if status == .owned {
                Stepper("Bottles owned: \(max(Int(bottlesText) ?? 1, 0))",
                        value: Binding(
                            get: { max(Int(bottlesText) ?? 1, 0) },
                            set: { bottlesText = String($0) }),
                        in: 0...20)
            }
        } header: {
            Text("Bottle")
        }
    }

    private var pyramidSection: some View {
        Section {
            slotEditor(.top, names: topNotes)
            slotEditor(.heart, names: heartNotes)
            slotEditor(.base, names: baseNotes)
        } header: {
            Text("Note pyramid")
        } footer: {
            Text("Tap a slot to add notes from the library or your own. The dominant family sets the swatch.")
        }
    }

    private func slotEditor(_ slot: NoteSlot, names: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                pickerSlot = slot
            } label: {
                HStack {
                    Text(slot.rawValue)
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text(names.isEmpty ? "Add" : "\(names.count)")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
            if !names.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(names, id: \.self) { n in
                        Button {
                            removeNote(n, from: slot)
                        } label: {
                            HStack(spacing: 4) {
                                NoteChip(name: n, family: familyByName[n] ?? .floral)
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.inkFaint)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove \(n)")
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var seasonOccasionSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Seasons").font(Theme.rounded(13, .semibold)).foregroundStyle(Theme.inkSoft)
                FlowLayout(spacing: 8) {
                    ForEach(Season.allCases) { s in
                        toggleChip(s.rawValue, symbol: s.symbol,
                                   on: seasons.contains(s), tint: s.hue) {
                            if seasons.contains(s) { seasons.remove(s) } else { seasons.insert(s) }
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Occasions").font(Theme.rounded(13, .semibold)).foregroundStyle(Theme.inkSoft)
                FlowLayout(spacing: 8) {
                    ForEach(Occasion.allCases) { o in
                        toggleChip(o.rawValue, symbol: o.symbol,
                                   on: occasions.contains(o), tint: Theme.accent) {
                            if occasions.contains(o) { occasions.remove(o) } else { occasions.insert(o) }
                        }
                    }
                }
            }
        } header: {
            Text("When to wear")
        }
    }

    private func toggleChip(_ text: String, symbol: String, on: Bool, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
            Haptics.tap(settings.hapticsEnabled)
        }) {
            HStack(spacing: 4) {
                Image(systemName: symbol).font(.system(size: 11, weight: .semibold))
                Text(text).font(Theme.rounded(13, .medium))
            }
            .foregroundStyle(on ? .white : tint)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(Capsule().fill(on ? tint : tint.opacity(0.14)))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private var ratingsSection: some View {
        Section {
            HStack {
                Text("Rating").font(Theme.rounded(15)).foregroundStyle(Theme.ink)
                Spacer()
                StarPicker(rating: $rating)
            }
            MeterStepper(title: "Longevity", symbol: "hourglass", value: $longevity)
            MeterStepper(title: "Sillage", symbol: "wind", value: $sillage)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Juice color").font(Theme.rounded(15)).foregroundStyle(Theme.ink)
                    Spacer()
                    Circle()
                        .fill(Color(hue: colorHue, saturation: 0.5, brightness: 0.82))
                        .frame(width: 22, height: 22)
                        .overlay(Circle().strokeBorder(Theme.hairline))
                }
                Slider(value: $colorHue, in: 0...1)
                    .tint(Theme.accent)
                    .accessibilityLabel("Juice color hue")
            }
        } header: {
            Text("Impressions")
        }
    }

    private var detailsSection: some View {
        Section {
            TextField("Notes (optional)", text: $noteText, axis: .vertical)
                .lineLimit(2...5)
        } header: {
            Text("Your notes")
        }
    }

    // MARK: Note helpers

    private func names(for slot: NoteSlot) -> [String] {
        switch slot {
        case .top: return topNotes
        case .heart: return heartNotes
        case .base: return baseNotes
        }
    }

    private func toggle(_ note: ScentNote, in slot: NoteSlot) {
        familyByName[note.name] = note.family
        switch slot {
        case .top: toggleIn(&topNotes, note.name)
        case .heart: toggleIn(&heartNotes, note.name)
        case .base: toggleIn(&baseNotes, note.name)
        }
    }

    private func toggleIn(_ arr: inout [String], _ name: String) {
        if let idx = arr.firstIndex(of: name) { arr.remove(at: idx) } else { arr.append(name) }
    }

    private func removeNote(_ name: String, from slot: NoteSlot) {
        switch slot {
        case .top: topNotes.removeAll { $0 == name }
        case .heart: heartNotes.removeAll { $0 == name }
        case .base: baseNotes.removeAll { $0 == name }
        }
    }

    // MARK: Load & save

    private func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true

        // Seed the family lookup from the store.
        let lib = NoteLibrary.fetchAll(context: context)
        for (k, v) in lib { familyByName[k] = v.family }

        if let existing {
            name = existing.name
            house = existing.house
            concentration = existing.concentration
            status = existing.status
            sizeText = trimmedNumber(existing.sizeML)
            priceText = existing.pricePaid > 0 ? trimmedNumber(existing.pricePaid) : ""
            bottlesText = String(existing.bottlesOwned)
            rating = existing.rating
            longevity = existing.longevityRating
            sillage = existing.sillageRating
            colorHue = existing.colorHue
            seasons = existing.seasons
            occasions = existing.occasions
            noteText = existing.notes
            topNotes = existing.orderedNotes(in: .top).map(\.displayName)
            heartNotes = existing.orderedNotes(in: .heart).map(\.displayName)
            baseNotes = existing.orderedNotes(in: .base).map(\.displayName)
            for p in existing.placements { familyByName[p.displayName] = p.family }
        } else {
            status = defaultStatus
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedHouse = house.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            fail("Please give the fragrance a name.")
            return
        }
        guard !trimmedHouse.isEmpty else {
            fail("Please add the house (brand).")
            return
        }
        let size = Double(sizeText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let price = Double(priceText.replacingOccurrences(of: ",", with: ".")) ?? 0
        guard size >= 0 else { fail("Size must be 0 or more."); return }
        guard price >= 0 else { fail("Price must be 0 or more."); return }
        validationMessage = nil

        let bottles = max(Int(bottlesText) ?? 1, 0)
        let target: Fragrance
        if let existing {
            existing.name = trimmedName
            existing.house = trimmedHouse
            existing.concentration = concentration
            existing.status = status
            existing.sizeML = max(0, size)
            existing.pricePaid = max(0, price)
            existing.bottlesOwned = status == .owned ? max(bottles, 1) : bottles
            existing.rating = rating
            existing.longevityRating = longevity
            existing.sillageRating = sillage
            existing.colorHue = colorHue
            existing.seasons = seasons
            existing.occasions = occasions
            existing.notes = noteText
            target = existing
            // Replace placements wholesale.
            for p in existing.placements { context.delete(p) }
            existing.placements.removeAll()
        } else {
            let f = Fragrance(name: trimmedName,
                              house: trimmedHouse,
                              concentration: concentration,
                              seasons: seasons,
                              occasions: occasions,
                              sizeML: max(0, size),
                              pricePaid: max(0, price),
                              bottlesOwned: status == .owned ? max(bottles, 1) : bottles,
                              status: status,
                              rating: rating,
                              longevityRating: longevity,
                              sillageRating: sillage,
                              colorHue: colorHue,
                              notes: noteText)
            context.insert(f)
            target = f
        }

        applyPlacements(to: target)
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }

    private func applyPlacements(to fragrance: Fragrance) {
        let lib = NoteLibrary.fetchAll(context: context)
        func attach(_ names: [String], _ slot: NoteSlot) {
            for (i, name) in names.enumerated() {
                let note: ScentNote
                if let existing = lib[name] {
                    note = existing
                } else {
                    let created = ScentNote(name: name, family: familyByName[name] ?? .floral, isSeeded: false)
                    context.insert(created)
                    note = created
                }
                let placement = NotePlacement(slot: slot, note: note, order: i)
                placement.fragrance = fragrance
                fragrance.placements.append(placement)
            }
        }
        attach(topNotes, .top)
        attach(heartNotes, .heart)
        attach(baseNotes, .base)
    }

    private func fail(_ message: String) {
        validationMessage = message
        Haptics.error(settings.hapticsEnabled)
    }

    private func trimmedNumber(_ value: Double) -> String {
        if value == value.rounded() { return String(Int(value)) }
        return String(format: "%.1f", value)
    }
}

/// Small stepper for the 1...5 longevity/sillage meters used inside the editor.
private struct MeterStepper: View {
    let title: String
    let symbol: String
    @Binding var value: Int

    var body: some View {
        Stepper(value: $value, in: 1...5) {
            HStack(spacing: 8) {
                Image(systemName: symbol).foregroundStyle(Theme.accent)
                Text(title).font(Theme.rounded(15)).foregroundStyle(Theme.ink)
                Spacer()
                Text("\(value)/5")
                    .font(Theme.rounded(13, .medium))
                    .foregroundStyle(Theme.inkSoft)
                    .monospacedDigit()
            }
        }
        .accessibilityValue("\(value) of 5")
    }
}

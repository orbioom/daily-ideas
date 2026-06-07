import SwiftUI
import SwiftData

struct PlantingEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Crop.name) private var crops: [Crop]
    @Query(sort: \Bed.name) private var beds: [Bed]

    @State private var cropID: PersistentIdentifier?
    @State private var bedID: PersistentIdentifier?
    @State private var quantity = 1
    @State private var sowDate = Date.now
    @State private var status: PlantingStatus = .planned
    @State private var notes = ""
    @State private var loaded = false

    private var selectedCrop: Crop? { crops.first { $0.persistentModelID == cropID } }
    private var selectedBed: Bed? { beds.first { $0.persistentModelID == bedID } }

    private var schedule: CropSchedule? {
        selectedCrop?.schedule(springFrost: Season.springFrost(), fallFrost: Season.fallFrost())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if crops.isEmpty {
                    EmptyStateView(icon: "leaf",
                                   title: "No crops yet",
                                   message: "Add a crop to the catalog first, then schedule a planting.")
                } else {
                    Form {
                        Section("Crop") {
                            Picker("Crop", selection: $cropID) {
                                ForEach(crops) { c in Text(c.name).tag(Optional(c.persistentModelID)) }
                            }
                        }.listRowBackground(Color.clear)

                        if let sched = schedule {
                            Section("Suggested timing") {
                                if let indoor = sched.indoorSow {
                                    MilestoneRow(symbol: "house", label: "Start indoors", date: indoor, tint: Brand.info)
                                }
                                MilestoneRow(symbol: selectedCrop?.method == .transplant ? "arrow.up.forward" : "circle.dotted",
                                             label: selectedCrop?.method == .transplant ? "Transplant" : "Direct sow",
                                             date: sched.plantOrSow, tint: Brand.live)
                                MilestoneRow(symbol: "basket", label: "First harvest",
                                             date: sched.firstHarvest, tint: Brand.magic)
                                Button("Use suggested date") {
                                    sowDate = sched.plantOrSow; Haptics.selection()
                                }
                                .font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
                            }.listRowBackground(Color.clear)
                        }

                        Section("Placement") {
                            Picker("Bed", selection: $bedID) {
                                Text("Unassigned").tag(Optional<PersistentIdentifier>.none)
                                ForEach(beds) { b in Text(b.name).tag(Optional(b.persistentModelID)) }
                            }
                            Stepper("Quantity: \(quantity)", value: $quantity, in: 1...500)
                            DatePicker("Sow date", selection: $sowDate, displayedComponents: .date)
                            Picker("Status", selection: $status) {
                                ForEach(PlantingStatus.allCases) { s in Text(s.label).tag(s) }
                            }
                        }.listRowBackground(Color.clear)

                        Section("Notes") {
                            TextField("Optional", text: $notes, axis: .vertical).lineLimit(2...4)
                        }.listRowBackground(Color.clear)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("New planting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(selectedCrop == nil)
                }
            }
            .onAppear(perform: load)
            .onChange(of: cropID) { _, _ in
                if let s = schedule { sowDate = s.plantOrSow }
            }
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        cropID = crops.first { $0.isFavorite }?.persistentModelID ?? crops.first?.persistentModelID
        bedID = beds.first?.persistentModelID
        if let s = schedule { sowDate = s.plantOrSow }
    }

    private func save() {
        guard let crop = selectedCrop else { return }
        let p = Planting(cropName: crop.name, category: crop.category, year: Season.currentYear,
                         sowDate: sowDate, method: crop.method,
                         daysToMaturity: crop.daysToMaturity, quantity: quantity,
                         status: status, notes: notes.trimmingCharacters(in: .whitespaces))
        if let bed = selectedBed { p.bed = bed; bed.plantings.append(p) }
        context.insert(p)
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

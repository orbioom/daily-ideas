import SwiftUI
import SwiftData

struct TripDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var trip: CampTrip
    @State private var showEdit = false
    @State private var showAddGear = false
    @State private var showAddMeal = false
    @State private var showAddNature = false
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            tripHeader
            Picker("Section", selection: $selectedTab) {
                Text("Gear").tag(0)
                Text("Meals").tag(1)
                Text("Nature").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .accessibilityLabel("Trip section selector")

            switch selectedTab {
            case 0: GearChecklistView(trip: trip, showAdd: $showAddGear)
            case 1: MealPlannerView(trip: trip, showAdd: $showAddMeal)
            default: NatureJournalView(trip: trip, showAdd: $showAddNature)
            }
        }
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showEdit = true }) { Image(systemName: "pencil") }
                    .accessibilityLabel("Edit trip")
            }
        }
        .sheet(isPresented: $showEdit) { AddEditTripView(trip: trip) }
        .sheet(isPresented: $showAddGear) { AddGearView(trip: trip) }
        .sheet(isPresented: $showAddMeal) { AddMealView(trip: trip) }
        .sheet(isPresented: $showAddNature) { AddNatureLogView(trip: trip) }
    }

    private var tripHeader: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if !trip.campsite.isEmpty {
                        Label(trip.campsite, systemImage: "mappin.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(CampfireTheme.accent)
                    }
                    Text("\(trip.campType.rawValue) · \(trip.duration) night\(trip.duration == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(CampfireTheme.secondaryLabel)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    if trip.rating > 0 {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { i in
                                Image(systemName: i <= trip.rating ? "star.fill" : "star")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                            }
                        }
                        .accessibilityLabel("Rating: \(trip.rating) stars")
                    }
                    Text(trip.status.rawValue)
                        .font(.caption.weight(.medium))
                        .foregroundColor(CampfireTheme.statusColor(trip.status))
                }
            }
            .padding(.horizontal)

            if !trip.gearItems.isEmpty {
                HStack {
                    Text("Gear: \(trip.packedCount)/\(trip.gearItems.count) packed")
                        .font(.caption)
                        .foregroundColor(CampfireTheme.secondaryLabel)
                    Spacer()
                }
                .padding(.horizontal)
                ProgressView(value: trip.gearProgress)
                    .tint(CampfireTheme.forest)
                    .padding(.horizontal)
                    .accessibilityLabel("Gear packed: \(Int(trip.gearProgress*100))%")
            }
        }
        .padding(.vertical, 8)
        .background(CampfireTheme.secondary)
    }
}

struct GearChecklistView: View {
    @Environment(\.modelContext) private var context
    let trip: CampTrip
    @Binding var showAdd: Bool
    @State private var catFilter: GearCategory?

    var filtered: [GearItem] {
        let items = trip.gearItems
        guard let f = catFilter else { return items.sorted { $0.name < $1.name } }
        return items.filter { $0.category == f }.sorted { $0.name < $1.name }
    }

    var body: some View {
        List {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        catChip("All", selected: catFilter == nil) { catFilter = nil }
                        ForEach(GearCategory.allCases, id: \.self) { c in
                            catChip(c.rawValue, selected: catFilter == c) { catFilter = catFilter == c ? nil : c }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                .listRowBackground(Color.clear)
            }

            if filtered.isEmpty {
                Section {
                    VStack(spacing: 8) {
                        Text("No gear yet").foregroundColor(CampfireTheme.secondaryLabel)
                        Button("Add Gear") { showAdd = true }.font(.subheadline)
                            .accessibilityLabel("Add gear item")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
            } else {
                let groups = Dictionary(grouping: filtered) { $0.category.rawValue }
                ForEach(groups.sorted(by: { $0.key < $1.key }), id: \.key) { cat, items in
                    Section(cat) {
                        ForEach(items) { item in
                            GearItemRow(item: item)
                        }
                        .onDelete { idx in
                            let sorted = items.sorted { $0.name < $1.name }
                            for i in idx { context.delete(sorted[i]) }
                            try? context.save()
                        }
                    }
                }
            }

            Section {
                Button(action: { showAdd = true }) {
                    Label("Add Gear", systemImage: "plus.circle")
                        .foregroundColor(CampfireTheme.accent)
                }
                .accessibilityLabel("Add gear item")
            }
        }
        .listStyle(.insetGrouped)
    }

    private func catChip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(selected ? CampfireTheme.forest : CampfireTheme.secondary))
                .foregroundColor(selected ? .white : CampfireTheme.secondaryLabel)
        }
        .accessibilityLabel(label + (selected ? ", selected" : ""))
    }
}

struct GearItemRow: View {
    @Environment(\.modelContext) private var context
    @Bindable var item: GearItem

    var body: some View {
        HStack(spacing: 10) {
            Button(action: { item.packed.toggle(); try? context.save() }) {
                Image(systemName: item.packed ? "checkmark.square.fill" : "square")
                    .foregroundColor(item.packed ? CampfireTheme.forest : CampfireTheme.secondaryLabel)
                    .font(.title3)
            }
            .accessibilityLabel(item.packed ? "Mark as not packed" : "Mark as packed")

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .strikethrough(item.packed)
                    .foregroundColor(item.packed ? CampfireTheme.secondaryLabel : CampfireTheme.label)
                if !item.notes.isEmpty {
                    Text(item.notes).font(.caption).foregroundColor(CampfireTheme.secondaryLabel)
                }
            }
            Spacer()
            if !item.owned {
                Text("Need to buy")
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(Color.orange.opacity(0.12)))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name)\(item.packed ? ", packed" : ", not packed")")
    }
}

struct MealPlannerView: View {
    @Environment(\.modelContext) private var context
    let trip: CampTrip
    @Binding var showAdd: Bool

    var mealsByDay: [(Int, [MealPlan])] {
        var d: [Int: [MealPlan]] = [:]
        for meal in trip.mealPlans { d[meal.dayNumber, default: []].append(meal) }
        return d.sorted { $0.key < $1.key }
    }

    var body: some View {
        List {
            if trip.mealPlans.isEmpty {
                Section {
                    VStack(spacing: 8) {
                        Text("No meals planned yet").foregroundColor(CampfireTheme.secondaryLabel)
                        Button("Plan a Meal") { showAdd = true }
                            .accessibilityLabel("Plan a meal")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
            } else {
                ForEach(mealsByDay, id: \.0) { day, meals in
                    Section("Day \(day)") {
                        ForEach(meals.sorted { $0.mealType.rawValue < $1.mealType.rawValue }) { meal in
                            MealRow(meal: meal)
                        }
                        .onDelete { idx in
                            let sorted = meals.sorted { $0.mealType.rawValue < $1.mealType.rawValue }
                            for i in idx { context.delete(sorted[i]) }
                            try? context.save()
                        }
                    }
                }
            }
            Section {
                Button(action: { showAdd = true }) {
                    Label("Add Meal", systemImage: "plus.circle")
                        .foregroundColor(CampfireTheme.accent)
                }
                .accessibilityLabel("Add meal plan")
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct MealRow: View {
    let meal: MealPlan
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(meal.mealType.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(CampfireTheme.accent)
                Spacer()
                Text(meal.prepMethod.rawValue)
                    .font(.caption2)
                    .foregroundColor(CampfireTheme.secondaryLabel)
            }
            Text(meal.description)
                .font(.subheadline)
                .foregroundColor(CampfireTheme.label)
            if !meal.ingredients.isEmpty {
                Text(meal.ingredients)
                    .font(.caption)
                    .foregroundColor(CampfireTheme.secondaryLabel)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(meal.mealType.rawValue): \(meal.description)")
    }
}

struct NatureJournalView: View {
    @Environment(\.modelContext) private var context
    let trip: CampTrip
    @Binding var showAdd: Bool

    var logs: [NatureLog] { trip.natureLogs.sorted { $0.date > $1.date } }

    var body: some View {
        List {
            if logs.isEmpty {
                Section {
                    VStack(spacing: 8) {
                        Text("No nature sightings yet").foregroundColor(CampfireTheme.secondaryLabel)
                        Button("Log a Sighting") { showAdd = true }
                            .accessibilityLabel("Log a nature sighting")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
            } else {
                ForEach(logs) { log in
                    NatureLogRow(log: log)
                }
                .onDelete { idx in
                    for i in idx { context.delete(logs[i]) }
                    try? context.save()
                }
            }
            Section {
                Button(action: { showAdd = true }) {
                    Label("Log Sighting", systemImage: "binoculars.fill")
                        .foregroundColor(CampfireTheme.accent)
                }
                .accessibilityLabel("Log a nature sighting")
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct NatureLogRow: View {
    let log: NatureLog
    private static let fmt: DateFormatter = { let f = DateFormatter(); f.dateStyle = .short; return f }()

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: log.category.icon)
                .foregroundColor(CampfireTheme.forest)
                .font(.title3)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(log.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(CampfireTheme.label)
                Text(log.category.rawValue + " · " + Self.fmt.string(from: log.date))
                    .font(.caption)
                    .foregroundColor(CampfireTheme.secondaryLabel)
                if !log.description.isEmpty {
                    Text(log.description)
                        .font(.caption)
                        .foregroundColor(CampfireTheme.secondaryLabel)
                        .lineLimit(2)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(log.category.rawValue): \(log.title)")
    }
}

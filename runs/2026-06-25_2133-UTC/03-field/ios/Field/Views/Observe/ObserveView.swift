import SwiftUI
import SwiftData

struct ObserveView: View {
    @Query(sort: \Observation.date, order: .reverse) private var observations: [Observation]
    @Environment(\.modelContext) private var context
    @State private var showingAdd = false
    @State private var classFilter: SpeciesClass?
    @State private var seeded = false

    private var filtered: [Observation] {
        guard let c = classFilter else { return observations }
        return observations.filter { $0.speciesClass == c }
    }

    private var grouped: [(String, [Observation])] {
        let fmt = DateFormatter(); fmt.dateStyle = .long
        var groups: [String: [Observation]] = [:]
        var order: [String] = []
        for o in filtered {
            let key = fmt.string(from: o.date)
            if groups[key] == nil { order.append(key); groups[key] = [] }
            groups[key]?.append(o)
        }
        return order.map { ($0, groups[$0] ?? []) }
    }

    private var totalLifers: Int { observations.filter { $0.isLifer }.count }
    private var todayCount: Int {
        observations.filter { Calendar.current.isDateInToday($0.date) }.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if observations.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        statsRow
                        classFilterBar
                        observationList
                    }
                }
            }
            .navigationTitle("Field")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        FieldHaptics.impact(.medium)
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(FieldTheme.fern)
                    }
                    .accessibilityLabel("Log new observation")
                }
            }
            .sheet(isPresented: $showingAdd) { ObservationFormView(observation: nil) }
            .onAppear {
                if observations.isEmpty && !seeded {
                    FieldSeeder.seed(context: context)
                    seeded = true
                }
            }
            .navigationDestination(for: Observation.self) { obs in
                ObservationDetailView(observation: obs)
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            FieldStatChip(value: "\(observations.count)", label: "Sightings", icon: "binoculars.fill")
            FieldStatChip(value: "\(totalLifers)", label: "Lifers", icon: "star.fill")
            FieldStatChip(value: "\(uniqueSpeciesCount)", label: "Species", icon: "leaf.fill")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var classFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button("All") { classFilter = nil }
                    .fieldChip(isSelected: classFilter == nil)

                ForEach(SpeciesClass.allCases) { sc in
                    Button {
                        classFilter = sc
                    } label: {
                        HStack(spacing: 4) {
                            Text(sc.emoji).font(.caption)
                            Text(sc.rawValue).font(.caption.weight(.semibold))
                        }
                    }
                    .fieldChip(isSelected: classFilter == sc, color: sc.color)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    private var observationList: some View {
        List {
            ForEach(grouped, id: \.0) { dateKey, dayObs in
                Section {
                    ForEach(dayObs) { obs in
                        NavigationLink(value: obs) {
                            ObsRowView(obs: obs)
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                        .listRowBackground(Color.clear)
                    }
                    .onDelete { idx in
                        for i in idx { context.delete(dayObs[i]) }
                        try? context.save()
                    }
                } header: {
                    HStack {
                        Text(dateKey).font(.subheadline.bold())
                        Spacer()
                        Text("\(dayObs.count) sighting\(dayObs.count == 1 ? "" : "s")")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 60)
            Image(systemName: "binoculars")
                .font(.system(size: 64))
                .foregroundStyle(FieldTheme.fern.opacity(0.6))
                .accessibilityHidden(true)
            Text("No observations yet")
                .font(.title2.bold())
            Text("Tap + to log your first sighting and start your field journal.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer(minLength: 40)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No observations yet. Tap plus to log your first sighting.")
    }

    private var uniqueSpeciesCount: Int {
        Set(observations.map { $0.speciesName.lowercased() }).count
    }
}

struct FieldStatChip: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundStyle(FieldTheme.fern).accessibilityHidden(true)
            Text(value).font(.headline.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

struct ObsRowView: View {
    let obs: Observation

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(obs.speciesClass.color.opacity(0.15)).frame(width: 44, height: 44)
                Text(obs.speciesClass.emoji).font(.title3)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(obs.displayName).font(.subheadline.bold())
                    if obs.isLifer { LiferBadge() }
                }
                HStack(spacing: 6) {
                    if !obs.locationName.isEmpty {
                        Image(systemName: "mappin").font(.caption2)
                        Text(obs.locationName).font(.caption).foregroundStyle(.secondary)
                    }
                    if obs.count > 1 {
                        Text("× \(obs.count)").font(.caption).foregroundStyle(FieldTheme.fern)
                    }
                }
            }

            Spacer()

            SpeciesClassBadge(speciesClass: obs.speciesClass)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(obs.displayName), \(obs.speciesClass.rawValue), \(obs.locationName)\(obs.isLifer ? ", lifer" : "")")
    }
}

private extension View {
    func fieldChip(isSelected: Bool, color: Color = FieldTheme.fern) -> some View {
        self
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
    }
}

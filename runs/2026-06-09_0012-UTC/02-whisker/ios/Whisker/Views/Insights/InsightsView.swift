import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query private var pets: [Pet]
    @AppStorage("whisker.weightUnit") private var unitRaw = WeightUnit.kg.rawValue
    @State private var selectedPet: Pet?

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }
    private var active: [Pet] { pets.filter { !$0.isArchived } }
    private var chosen: Pet? { selectedPet ?? active.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                if active.isEmpty {
                    EmptyStateView(icon: "chart.xyaxis.line",
                                   title: "No pets yet",
                                   message: "Add a pet and log a few weights to see insights.")
                        .glassCard().padding(20)
                } else {
                    VStack(spacing: 18) {
                        overviewGrid
                        petPicker
                        if let pet = chosen {
                            weightCard(pet)
                            careLoadCard(pet)
                        }
                    }
                    .padding(20)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Insights")
        }
    }

    private var overviewGrid: some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible())]
        let totalTasks = active.reduce(0) { $0 + $1.activeTasks.count }
        let due = PetEngine.dueTasks(for: active).filter { $0.daysUntil <= 0 }.count
        return LazyVGrid(columns: cols, spacing: 14) {
            tile("Pets", "\(active.count)", "pawprint.fill", Brand.magic)
            tile("Care tasks", "\(totalTasks)", "checklist", Brand.info)
            tile("Due now", "\(due)", "exclamationmark.circle.fill", due > 0 ? Brand.warn : Brand.live)
            tile("Records", "\(active.reduce(0) { $0 + $1.events.count + $1.weights.count })", "doc.text.fill", Brand.live)
        }
    }

    private func tile(_ label: String, _ value: String, _ icon: String, _ tint: Color) -> some View {
        GlassCard(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon).foregroundStyle(tint).accessibilityHidden(true)
                Text(value).font(Brand.mono(22, weight: .semibold)).foregroundStyle(Brand.text)
                Text(label).font(.caption).foregroundStyle(Brand.text3)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var petPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(active) { pet in
                    let isSel = chosen?.persistentModelID == pet.persistentModelID
                    Button {
                        Haptics.selection(); selectedPet = pet
                    } label: {
                        HStack(spacing: 8) {
                            PetAvatar(pet: pet, size: 24)
                            Text(pet.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(isSel ? pet.color.color.opacity(0.18) : Color.clear, in: Capsule())
                        .overlay(Capsule().strokeBorder(isSel ? pet.color.color : Brand.hairline, lineWidth: 1))
                    }
                    .accessibilityAddTraits(isSel ? .isSelected : [])
                }
            }
        }
    }

    private func weightCard(_ pet: Pet) -> some View {
        let series = PetEngine.weightSeries(for: pet)
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "\(pet.name) · weight")
                if series.count < 2 {
                    Text("Log at least two weights for \(pet.name) to see a trend.")
                        .font(.subheadline).foregroundStyle(Brand.text3)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 10)
                } else {
                    Chart(series) { p in
                        LineMark(x: .value("Date", p.date), y: .value("Weight", unit.fromKg(p.kilograms)))
                            .foregroundStyle(pet.color.color).interpolationMethod(.catmullRom)
                        PointMark(x: .value("Date", p.date), y: .value("Weight", unit.fromKg(p.kilograms)))
                            .foregroundStyle(pet.color.color).symbolSize(18)
                    }
                    .frame(height: 200)
                    .chartYScale(domain: .automatic(includesZero: false))
                    .accessibilityLabel("Weight chart for \(pet.name)")
                }
            }
        }
    }

    private func careLoadCard(_ pet: Pet) -> some View {
        let counts: [(CareKind, Int)] = Dictionary(grouping: pet.activeTasks, by: { $0.kind })
            .map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "\(pet.name) · care mix")
                if counts.isEmpty {
                    Text("No care tasks for \(pet.name) yet.").font(.subheadline).foregroundStyle(Brand.text3)
                } else {
                    ForEach(counts, id: \.0) { kind, count in
                        HStack {
                            Image(systemName: kind.icon).foregroundStyle(kind.tint).frame(width: 26)
                            Text(kind.title).font(.subheadline).foregroundStyle(Brand.text)
                            Spacer()
                            Text("\(count)").font(Brand.mono(14)).foregroundStyle(Brand.text2)
                        }
                        .padding(.vertical, 2)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }
}

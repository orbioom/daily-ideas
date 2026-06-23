import SwiftUI
import SwiftData
import Charts

/// Weight tab — per-pet weight trend chart with stats and history, plus logging.
struct WeightView: View {
    @Bindable var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Query(sort: \Pet.createdAt) private var pets: [Pet]

    @State private var selectedPetID: UUID?
    @State private var showingAdd = false

    private var selectedPet: Pet? {
        if let id = selectedPetID { return pets.first { $0.id == id } }
        return pets.first
    }

    private var entries: [WeightEntry] {
        (selectedPet?.weightEntries ?? []).sorted { $0.date < $1.date }
    }

    private var unit: WeightUnit { settings.preferredWeightUnit }

    var body: some View {
        NavigationStack {
            Group {
                if pets.isEmpty {
                    EmptyStateView(symbol: "chart.xyaxis.line",
                                   title: "No pets to weigh",
                                   message: "Add a pet to start tracking their weight over time.")
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            petPicker
                            if entries.isEmpty {
                                PetalCard {
                                    EmptyStateView(symbol: "scalemass",
                                                   title: "No weigh-ins yet",
                                                   message: "Tap the + to log \(selectedPet?.name ?? "your pet")'s first weight.",
                                                   actionTitle: "Add weight",
                                                   action: { showingAdd = true })
                                }
                            } else {
                                statRow
                                chartCard
                                historyCard
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .petalScreenBackground()
            .navigationTitle("Weight")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .disabled(pets.isEmpty)
                        .accessibilityLabel("Add weight entry")
                }
            }
            .sheet(isPresented: $showingAdd) {
                if let pet = selectedPet {
                    WeightFormView(pet: pet, settings: settings)
                }
            }
        }
    }

    private var petPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(pets) { pet in
                    let isSel = (selectedPet?.id == pet.id)
                    Button {
                        selectedPetID = pet.id
                        Haptics.selection(enabled: settings.hapticsEnabled)
                    } label: {
                        HStack(spacing: 8) {
                            PetAvatar(symbol: pet.avatarSymbol, tint: pet.avatarTint.color, size: 26)
                            Text(pet.name).font(.subheadline.weight(.medium))
                                .foregroundStyle(isSel ? Color.white : Theme.primaryText)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(
                            Capsule().fill(isSel ? pet.avatarTint.color : Theme.card)
                        )
                        .overlay(Capsule().strokeBorder(Theme.divider, lineWidth: isSel ? 0 : 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(pet.name)
                    .accessibilityAddTraits(isSel ? .isSelected : [])
                }
            }
        }
    }

    private var latest: WeightEntry? { entries.last }
    private var first: WeightEntry? { entries.first }

    private var changeKg: Double {
        guard let l = latest, let f = first, entries.count >= 2 else { return 0 }
        return l.kilograms - f.kilograms
    }

    private var statRow: some View {
        HStack(spacing: Theme.Metrics.spacing) {
            PetalCard {
                VStack(spacing: 4) {
                    Text(latest.map { Fmt.weight($0.kilograms, unit: unit) } ?? "—")
                        .font(.title3.bold()).foregroundStyle(Theme.primaryText)
                    Text("Current").font(.caption).foregroundStyle(Theme.secondaryText)
                }.frame(maxWidth: .infinity)
            }
            PetalCard {
                VStack(spacing: 4) {
                    HStack(spacing: 3) {
                        Image(systemName: changeKg > 0.01 ? "arrow.up.right" : (changeKg < -0.01 ? "arrow.down.right" : "minus"))
                            .font(.caption).accessibilityHidden(true)
                        Text(String(format: "%.1f %@", abs(unit.fromKilograms(changeKg)), unit.label))
                            .font(.title3.bold())
                    }
                    .foregroundStyle(changeKg > 0.01 ? Theme.amber : (changeKg < -0.01 ? Theme.success : Theme.secondaryText))
                    Text("Since first").font(.caption).foregroundStyle(Theme.secondaryText)
                }.frame(maxWidth: .infinity)
            }
            PetalCard {
                VStack(spacing: 4) {
                    Text("\(entries.count)").font(.title3.bold()).foregroundStyle(Theme.primaryText)
                    Text("Entries").font(.caption).foregroundStyle(Theme.secondaryText)
                }.frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var chartCard: some View {
        PetalCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Trend", trailing: unit.label)
                Chart(entries) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.displayWeight(in: unit))
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(selectedPet?.avatarTint.color ?? Theme.lilac)
                    .symbol(Circle().strokeBorder(lineWidth: 2))

                    AreaMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.displayWeight(in: unit))
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(colors: [(selectedPet?.avatarTint.color ?? Theme.lilac).opacity(0.3), .clear],
                                       startPoint: .top, endPoint: .bottom)
                    )
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
                .frame(height: 200)
                .accessibilityLabel("Weight trend for \(selectedPet?.name ?? "pet")")
                .accessibilityValue("\(entries.count) entries, current \(latest.map { Fmt.weight($0.kilograms, unit: unit) } ?? "unknown")")
            }
        }
    }

    private var historyCard: some View {
        PetalCard {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(title: "History")
                    .padding(.bottom, 6)
                ForEach(Array(entries.reversed().enumerated()), id: \.element.id) { idx, entry in
                    HStack {
                        Text(Fmt.mediumDate.string(from: entry.date))
                            .font(.subheadline).foregroundStyle(Theme.primaryText)
                        Spacer()
                        Text(Fmt.weight(entry.kilograms, unit: unit))
                            .font(.subheadline.weight(.medium)).foregroundStyle(Theme.secondaryText)
                        Button {
                            delete(entry)
                        } label: {
                            Image(systemName: "trash").font(.caption).foregroundStyle(Theme.danger)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Delete entry from \(Fmt.mediumDate.string(from: entry.date))")
                    }
                    .padding(.vertical, 8)
                    if idx < entries.count - 1 { Divider().overlay(Theme.divider) }
                }
            }
        }
    }

    private func delete(_ entry: WeightEntry) {
        context.delete(entry)
        try? context.save()
        Haptics.impact(.rigid, enabled: settings.hapticsEnabled)
    }
}

#Preview {
    WeightView(settings: AppSettings(hasOnboarded: true))
        .modelContainer(PersistenceController.preview.container)
}

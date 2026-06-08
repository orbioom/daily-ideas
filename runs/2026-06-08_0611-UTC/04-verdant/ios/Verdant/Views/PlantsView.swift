import SwiftUI
import SwiftData

struct PlantsView: View {
    @AppStorage("verdant.seasonal") private var seasonalAdjust = true
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Plant.order) private var allPlants: [Plant]
    @Query(sort: \Room.order) private var rooms: [Room]

    @State private var searchText = ""
    @State private var selectedRoomFilter: Room? = nil
    @State private var showAddPlant = false
    @State private var showArchived = false

    private var now: Date { Date() }

    private var filteredPlants: [Plant] {
        allPlants.filter { plant in
            guard !plant.archived || showArchived else { return false }
            let matchesRoom: Bool
            if let room = selectedRoomFilter {
                matchesRoom = plant.room?.id == room.id
            } else {
                matchesRoom = true
            }
            let matchesSearch: Bool
            if searchText.isEmpty {
                matchesSearch = true
            } else {
                let q = searchText.lowercased()
                matchesSearch = plant.nickname.lowercased().contains(q) ||
                    plant.species.lowercased().contains(q)
            }
            return matchesRoom && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                VStack(spacing: 0) {
                    if !rooms.isEmpty {
                        roomFilterBar
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    if filteredPlants.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: "leaf",
                            title: searchText.isEmpty ? "No plants yet" : "No results",
                            message: searchText.isEmpty
                                ? "Tap + to add your first plant."
                                : "Try a different name or species."
                        )
                        Spacer()
                    } else {
                        plantsGrid
                    }
                }
            }
            .navigationTitle("Plants")
            .searchable(text: $searchText, prompt: "Search plants")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(Brand.ease(0.3)) {
                            showArchived.toggle()
                        }
                        Haptics.tap()
                    } label: {
                        Image(systemName: showArchived ? "archivebox.fill" : "archivebox")
                            .foregroundStyle(showArchived ? Brand.live : Brand.text2)
                    }
                    .accessibilityLabel(showArchived ? "Hide archived plants" : "Show archived plants")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddPlant = true
                        Haptics.tap()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add new plant")
                }
            }
            .sheet(isPresented: $showAddPlant) {
                AddEditPlantView()
            }
        }
    }

    private var roomFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", symbol: "square.grid.2x2", isSelected: selectedRoomFilter == nil) {
                    Haptics.selection()
                    selectedRoomFilter = nil
                }
                ForEach(rooms) { room in
                    FilterChip(label: room.name, symbol: room.symbol, isSelected: selectedRoomFilter?.id == room.id) {
                        Haptics.selection()
                        selectedRoomFilter = selectedRoomFilter?.id == room.id ? nil : room
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var plantsGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 12)],
                spacing: 12
            ) {
                ForEach(filteredPlants) { plant in
                    NavigationLink(destination: PlantDetailView(plant: plant)) {
                        PlantGridCell(plant: plant, seasonalAdjust: seasonalAdjust, now: now)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(plant.nickname), \(plant.species.isEmpty ? "unknown species" : plant.species)")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
    }
}

private struct FilterChip: View {
    let label: String
    let symbol: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.caption2.weight(.semibold))
                    .accessibilityHidden(true)
                Text(label)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(isSelected ? .white : Brand.text2)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? Brand.live : Brand.live.opacity(0.0), in: Capsule())
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(isSelected ? Color.clear : Brand.hairline, lineWidth: 0.5))
        }
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct PlantGridCell: View {
    let plant: Plant
    let seasonalAdjust: Bool
    let now: Date

    private var status: CareStatus {
        CareEngine.status(plant: plant, seasonalAdjust: seasonalAdjust, now: now)
    }

    private var statusColor: Color {
        switch status {
        case .overdue:  return Brand.danger
        case .dueToday: return Brand.warn
        case .dueSoon:  return Brand.warn
        case .ok:       return Brand.live
        }
    }

    var body: some View {
        GlassCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(hex: plant.colorHex).opacity(0.18))
                            .frame(width: 40, height: 40)
                        Image(systemName: plant.symbol)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color(hex: plant.colorHex))
                    }
                    Spacer()
                    StatusDot(color: statusColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(plant.nickname)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.text)
                        .lineLimit(1)
                    if !plant.species.isEmpty {
                        Text(plant.species)
                            .font(.caption2)
                            .foregroundStyle(Brand.text3)
                            .lineLimit(1)
                    }
                }

                StatusDotLabel(status: status)

                if plant.archived {
                    Label("Archived", systemImage: "archivebox")
                        .font(.caption2)
                        .foregroundStyle(Brand.text3)
                }
            }
        }
    }
}

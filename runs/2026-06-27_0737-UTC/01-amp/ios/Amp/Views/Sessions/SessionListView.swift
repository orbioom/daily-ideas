import SwiftUI
import SwiftData

struct SessionListView: View {
    @Query(sort: \ChargingSession.date, order: .reverse) private var sessions: [ChargingSession]
    @Query private var vehicles: [Vehicle]
    @Query private var settingsArr: [AmpSettings]
    @Environment(\.modelContext) private var context

    @State private var showAdd = false
    @State private var filterVehicleID: UUID? = nil
    @State private var filterChargerType: ChargerType? = nil
    @State private var selectedSession: ChargingSession? = nil

    private var currencySymbol: String { settingsArr.first?.currencySymbol ?? "$" }

    private var filtered: [ChargingSession] {
        sessions.filter { s in
            (filterVehicleID == nil || s.vehicle?.id == filterVehicleID) &&
            (filterChargerType == nil || s.chargerType == filterChargerType)
        }
    }

    private var grouped: [(String, [ChargingSession])] {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        let dict = Dictionary(grouping: filtered) { fmt.string(from: $0.date) }
        return dict.sorted { a, b in
            guard let ad = filtered.first(where: { fmt.string(from: $0.date) == a.key })?.date,
                  let bd = filtered.first(where: { fmt.string(from: $0.date) == b.key })?.date else { return a.key > b.key }
            return ad > bd
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    emptyState
                } else {
                    List {
                        filterBar
                            .listRowBackground(Color.clear)
                            .listRowInsets(.init())
                        ForEach(grouped, id: \.0) { month, items in
                            Section(header: Text(month)) {
                                ForEach(items) { session in
                                    SessionRowView(session: session, currencySymbol: currencySymbol)
                                        .contentShape(Rectangle())
                                        .onTapGesture { selectedSession = session }
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                context.delete(session)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Sessions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add session")
                }
            }
            .sheet(isPresented: $showAdd) { AddSessionView() }
            .sheet(item: $selectedSession) { s in
                SessionDetailView(session: s, currencySymbol: currencySymbol)
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All Vehicles", isSelected: filterVehicleID == nil) {
                    filterVehicleID = nil
                }
                ForEach(vehicles) { v in
                    FilterChip(label: v.displayName, isSelected: filterVehicleID == v.id) {
                        filterVehicleID = filterVehicleID == v.id ? nil : v.id
                    }
                }
                Divider().frame(height: 24)
                FilterChip(label: "All Types", isSelected: filterChargerType == nil) {
                    filterChargerType = nil
                }
                ForEach(ChargerType.allCases, id: \.self) { t in
                    FilterChip(label: t.rawValue, isSelected: filterChargerType == t) {
                        filterChargerType = filterChargerType == t ? nil : t
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bolt.slash")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No sessions yet")
                .font(.title3.bold())
            Text("Tap + to log your first charge")
                .foregroundStyle(.secondary)
            Button("Log First Charge") { showAdd = true }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct SessionRowView: View {
    let session: ChargingSession
    let currencySymbol: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.chargerType.icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 36)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.vehicle?.displayName ?? "Unknown Vehicle")
                    .font(.subheadline.bold())
                Text(session.locationName.isEmpty ? session.chargerType.rawValue : session.locationName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f kWh", session.kwhAdded))
                    .font(.subheadline.bold())
                Text("\(currencySymbol)\(String(format: "%.2f", session.cost))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(session.vehicle?.displayName ?? "Vehicle"), \(String(format: "%.1f", session.kwhAdded)) kilowatt-hours, \(currencySymbol)\(String(format: "%.2f", session.cost))")
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

import SwiftUI
import SwiftData

enum TripSection: Hashable {
    case itinerary, stays, packing, budget
}

struct TripDetailView: View {
    @Bindable var trip: Trip
    @Environment(\.modelContext) private var context
    @State private var editingTrip = false

    private let engine = TripEngine()

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    if !trip.notes.isEmpty { notesCard }
                    hubGrid
                }
                .padding()
            }
        }
        .navigationTitle(trip.name.isEmpty ? "Trip" : trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { editingTrip = true } label: { Image(systemName: "pencil") }
                    .accessibilityLabel("Edit trip")
            }
        }
        .navigationDestination(for: TripSection.self) { section in
            switch section {
            case .itinerary: ItineraryView(trip: trip)
            case .stays:     StaysView(trip: trip)
            case .packing:   PackingView(trip: trip)
            case .budget:    BudgetView(trip: trip)
            }
        }
        .sheet(isPresented: $editingTrip) {
            TripEditorView(trip: trip, isNew: false)
        }
    }

    private var headerCard: some View {
        let status = engine.status(trip)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Eyebrow(text: status.label)
                Spacer()
                if !trip.destination.isEmpty {
                    Label(trip.destination, systemImage: "mappin")
                        .font(.caption).foregroundStyle(Brand.text2)
                }
            }
            Text(dateRange)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Brand.text)
            Text("\(engine.dayCount(trip)) days")
                .font(.subheadline).foregroundStyle(Brand.text3)
        }
        .glassCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Eyebrow(text: "Notes")
            Text(trip.notes).font(.subheadline).foregroundStyle(Brand.text2)
        }
        .glassCard()
    }

    private var hubGrid: some View {
        let (packed, total) = engine.packingProgress(trip)
        let gaps = engine.nightsWithoutLodging(trip)
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            hubTile(.itinerary, "Itinerary", "calendar.day.timeline.left",
                    detail: "\(trip.activities.count) plans")
            hubTile(.stays, "Stays", "bed.double.fill",
                    detail: gaps > 0 ? "\(gaps) night\(gaps == 1 ? "" : "s") to book" : "\(trip.lodgings.count) booked",
                    warn: gaps > 0)
            hubTile(.packing, "Packing", "suitcase.fill",
                    detail: total == 0 ? "Build a list" : "\(packed)/\(total) packed")
            hubTile(.budget, "Budget", "creditcard.fill",
                    detail: budgetDetail)
        }
    }

    private var budgetDetail: String {
        if let remaining = engine.budgetRemaining(trip) {
            return "\(Money.compact(remaining, code: trip.currencyCode)) left"
        }
        let spent = engine.totalSpent(trip)
        return spent > 0 ? "\(Money.compact(spent, code: trip.currencyCode)) spent" : "Set a budget"
    }

    private func hubTile(_ section: TripSection, _ title: String, _ symbol: String,
                         detail: String, warn: Bool = false) -> some View {
        NavigationLink(value: section) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Brand.text)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(warn ? Brand.warn : Brand.text2)
            }
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
            .glassCard(padding: 16)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(detail)")
    }

    private var dateRange: String {
        "\(Format.shortDate.string(from: trip.startDate)) – \(Format.shortDate.string(from: trip.endDate))"
    }
}

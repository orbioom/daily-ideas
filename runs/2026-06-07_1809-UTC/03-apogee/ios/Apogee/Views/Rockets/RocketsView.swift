import SwiftUI
import SwiftData

/// The Rockets tab: a list of every designed rocket with a stability dot, plus
/// full create / edit / delete. Tapping a row opens the detail + simulator.
struct RocketsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Rocket.createdAt, order: .reverse) private var rockets: [Rocket]
    @AppStorage("apogee.units") private var unitsRaw = LengthUnit.meters.rawValue
    @State private var editing: Rocket?
    @State private var showingNew = false

    private var units: LengthUnit { LengthUnit(rawValue: unitsRaw) ?? .meters }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                content
            }
            .navigationTitle("Rockets")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showingNew = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add rocket")
                }
            }
            .sheet(isPresented: $showingNew) {
                RocketEditView(rocket: nil)
            }
        }
    }

    @ViewBuilder private var content: some View {
        if rockets.isEmpty {
            EmptyStateView(
                icon: "airplane.departure",
                title: "No rockets yet",
                message: "Tap + to design your first rocket and check its stability.")
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(rockets) { rocket in
                        NavigationLink {
                            RocketDetailView(rocket: rocket)
                        } label: {
                            RocketRow(rocket: rocket, units: units)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                delete(rocket)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    private func delete(_ rocket: Rocket) {
        Haptics.warning()
        withAnimation(Brand.ease()) {
            context.delete(rocket)
            try? context.save()
        }
    }
}

/// One row in the rockets list.
private struct RocketRow: View {
    let rocket: Rocket
    let units: LengthUnit

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    StatusDot(color: rocket.stability.color)
                    Text(rocket.name.isEmpty ? "Untitled rocket" : rocket.name)
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                }
                Text("\(Format.mm(rocket.diameterMm)) · \(Format.grams(rocket.massGramsDry)) · \(Format.calibers(rocket.stabilityCal))")
                    .font(Brand.mono(12))
                    .foregroundStyle(Brand.text2)
            }
            Spacer()
            Badge(text: rocket.stability.label, color: rocket.stability.color)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Brand.text3)
                .accessibilityHidden(true)
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(rocket.name), \(rocket.stability.label), \(Format.calibers(rocket.stabilityCal))")
        .accessibilityHint("Opens rocket detail and simulator")
    }
}

import SwiftUI
import SwiftData

struct StaysView: View {
    @Bindable var trip: Trip
    @Environment(\.modelContext) private var context
    @State private var editingLodging: Lodging?

    private let engine = TripEngine()
    private let calendar = Calendar.current

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(spacing: 16) {
                    coverageCard
                    lodgingsCard
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    Haptics.tap()
                    editingLodging = newLodging()
                } label: { Label("Add stay", systemImage: "plus") }
                    .buttonStyle(InkButtonStyle())
                    .padding()
                    .background(.ultraThinMaterial)
            }
        }
        .navigationTitle("Stays")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingLodging) { LodgingEditorView(lodging: $0, trip: trip) }
    }

    private var coverageCard: some View {
        let coverage = engine.nightlyCoverage(trip)
        let gaps = coverage.filter { $0.lodging == nil }.count
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Where you sleep")
                    .font(.headline).foregroundStyle(Brand.text)
                Spacer()
                if gaps == 0 {
                    Label("All nights covered", systemImage: "checkmark.seal.fill")
                        .font(.caption).foregroundStyle(Brand.live)
                } else {
                    Label("\(gaps) gap\(gaps == 1 ? "" : "s")", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption).foregroundStyle(Brand.warn)
                }
            }
            ForEach(coverage) { night in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(Format.weekdayShort.string(from: night.night))
                            .font(Brand.mono(10)).foregroundStyle(Brand.text3)
                        Text(Format.dayOfMonth.string(from: night.night))
                            .font(.headline).foregroundStyle(Brand.text)
                    }
                    .frame(width: 40, alignment: .leading)

                    Rectangle()
                        .fill(night.lodging == nil ? Brand.warn.opacity(0.5) : Color(hex: trip.colorHex))
                        .frame(width: 3, height: 30)
                        .clipShape(Capsule())

                    if let lodging = night.lodging {
                        Text(lodging.name)
                            .font(.subheadline).foregroundStyle(Brand.text)
                    } else {
                        Text("No stay booked")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Brand.warn)
                    }
                    Spacer()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(Format.dayFull.string(from: night.night)), \(night.lodging?.name ?? "no stay booked")")
            }
        }
        .glassCard()
    }

    @ViewBuilder
    private var lodgingsCard: some View {
        if trip.lodgings.isEmpty {
            EmptyStateView(
                icon: "bed.double",
                title: "No stays added",
                message: "Add hotels, rentals, or hostels with check-in and check-out dates to see your nightly coverage above."
            )
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Bookings").font(.headline).foregroundStyle(Brand.text)
                ForEach(trip.lodgings.sorted { $0.checkIn < $1.checkIn }) { lodging in
                    Button { editingLodging = lodging } label: {
                        lodgingRow(lodging)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button(role: .destructive) {
                            context.delete(lodging); Haptics.warning()
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
            .glassCard()
        }
    }

    private func lodgingRow(_ lodging: Lodging) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "house.fill")
                .foregroundStyle(Color(hex: trip.colorHex))
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(lodging.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                Text("\(Format.shortDate.string(from: lodging.checkIn)) → \(Format.shortDate.string(from: lodging.checkOut))  ·  \(lodging.nights()) night\(lodging.nights() == 1 ? "" : "s")")
                    .font(.caption).foregroundStyle(Brand.text3)
                if lodging.cost > 0 {
                    Text(Money.string(lodging.cost, code: trip.currencyCode))
                        .font(Brand.mono(11)).foregroundStyle(Brand.text2)
                }
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }

    private func newLodging() -> Lodging {
        let ci = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: trip.startDate) ?? trip.startDate
        let co = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: trip.endDate) ?? trip.endDate
        let lodging = Lodging(name: "", checkIn: ci, checkOut: co, trip: trip)
        context.insert(lodging)
        return lodging
    }
}

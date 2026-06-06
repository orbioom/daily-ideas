import SwiftUI
import SwiftData

struct RunDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("distanceUnit") private var unitRaw = DistanceUnit.km.rawValue
    @Bindable var run: Run
    @State private var showEdit = false
    @State private var confirmDelete = false

    private var unit: DistanceUnit { DistanceUnit(rawValue: unitRaw) ?? .km }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(run.kind.rawValue, systemImage: run.kind.icon)
                            .font(.headline).foregroundStyle(Brand.text)
                        Spacer()
                        Text(run.date, format: .dateTime.weekday().month().day())
                            .font(Brand.mono(13)).foregroundStyle(Brand.text2)
                    }
                    Text(run.name).font(.title2.weight(.bold)).foregroundStyle(Brand.text)
                }
                .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)

                HStack(spacing: 12) {
                    StatTile(value: unit.format(meters: run.distanceMeters), label: "Distance")
                    StatTile(value: PaceMath.clock(run.durationSeconds), label: "Time")
                }
                HStack(spacing: 12) {
                    StatTile(value: unit.paceLabel(secPerKm: run.paceSecPerKm), label: "Pace", accent: Brand.magic)
                    StatTile(value: run.vdot > 0 ? String(format: "%.0f", run.vdot) : "—",
                             label: "VDOT", accent: Brand.info)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Perceived effort").font(.subheadline).foregroundStyle(Brand.text2)
                        Spacer()
                        Text("\(run.rpe) / 10").font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.text)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Brand.hairline).frame(height: 8)
                            Capsule().fill(rpeColor)
                                .frame(width: max(8, geo.size.width * Double(run.rpe) / 10), height: 8)
                        }
                    }.frame(height: 8)
                }
                .glassCard()

                if !run.notes.isEmpty {
                    Text(run.notes).font(.subheadline).foregroundStyle(Brand.text2)
                        .frame(maxWidth: .infinity, alignment: .leading).glassCard()
                }

                Button(role: .destructive) { confirmDelete = true } label: {
                    Label("Delete run", systemImage: "trash").frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle()).tint(Brand.danger)
            }
            .padding(16)
        }
        .background(Brand.pageBackground)
        .navigationTitle("Run").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Edit") { showEdit = true } } }
        .sheet(isPresented: $showEdit) { RunEditView(run: run) }
        .alert("Delete this run?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                context.delete(run); try? context.save(); Haptics.warning(); dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var rpeColor: Color {
        switch run.rpe {
        case ...3: return Brand.live
        case 4...6: return Brand.info
        case 7...8: return Brand.warn
        default: return Brand.danger
        }
    }
}

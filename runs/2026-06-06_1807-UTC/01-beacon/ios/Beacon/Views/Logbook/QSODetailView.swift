import SwiftUI
import SwiftData

struct QSODetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("distanceUnit") private var unitRaw = DistanceUnit.km.rawValue
    @AppStorage("myGrid") private var myGrid = ""
    @Bindable var qso: QSO
    @State private var showEdit = false
    @State private var confirmDelete = false

    private var unit: DistanceUnit { DistanceUnit(rawValue: unitRaw) ?? .km }

    private var path: (dist: String, bearing: Double, compass: String)? {
        guard !myGrid.isEmpty, !qso.theirGrid.isEmpty,
              let km = GridMath.distanceKm(from: myGrid, to: qso.theirGrid),
              let b = GridMath.bearing(from: myGrid, to: qso.theirGrid) else { return nil }
        return (unit.format(km: km), b, GridMath.compass(b))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(qso.callsign).font(.system(.largeTitle, design: .default, weight: .bold))
                            .foregroundStyle(Brand.text)
                        Spacer()
                        if qso.confirmed {
                            Label("QSL", systemImage: "checkmark.seal.fill")
                                .font(.subheadline).foregroundStyle(Brand.live)
                        }
                    }
                    Text(qso.dateTime, format: .dateTime.weekday().month().day().hour().minute())
                        .font(Brand.mono(14)).foregroundStyle(Brand.text2)
                    HStack(spacing: 6) {
                        Chip(text: qso.band.label, system: "antenna.radiowaves.left.and.right")
                        Chip(text: qso.mode.rawValue, system: "waveform")
                        Chip(text: String(format: "%.3f MHz", qso.freqMHz))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(padding: 20)

                HStack(spacing: 12) {
                    StatTile(value: qso.rstSent, label: "RST sent")
                    StatTile(value: qso.rstRcvd, label: "RST rcvd")
                }

                if let path {
                    VStack(alignment: .leading, spacing: 14) {
                        Eyebrow(text: "Path from \(myGrid)")
                        HStack(spacing: 16) {
                            CompassRose(bearing: path.bearing)
                            VStack(alignment: .leading, spacing: 8) {
                                metric("Distance", path.dist, Brand.text)
                                metric("Bearing", "\(Int(path.bearing.rounded()))° \(path.compass)", Brand.info)
                                if !qso.theirGrid.isEmpty { metric("Their grid", qso.theirGrid, Brand.text2) }
                            }
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(padding: 20)
                } else if !qso.theirGrid.isEmpty && myGrid.isEmpty {
                    Text("Set your grid in Settings to see distance and bearing.")
                        .font(.subheadline).foregroundStyle(Brand.text2)
                        .frame(maxWidth: .infinity, alignment: .leading).glassCard()
                }

                if !qso.theirName.isEmpty || !qso.theirQTH.isEmpty || qso.activation != nil || !qso.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        if !qso.theirName.isEmpty { detailRow("Operator", qso.theirName) }
                        if !qso.theirQTH.isEmpty { detailRow("QTH", qso.theirQTH) }
                        if let a = qso.activation { detailRow("Outing", a.title) }
                        if !qso.notes.isEmpty {
                            Divider().overlay(Brand.hairline)
                            Text(qso.notes).font(.subheadline).foregroundStyle(Brand.text2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)
                }

                Button(role: .destructive) { confirmDelete = true } label: {
                    Label("Delete contact", systemImage: "trash").frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle()).tint(Brand.danger)
            }
            .padding(16)
        }
        .background(Brand.pageBackground)
        .navigationTitle("Contact").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) { QSOEditView(qso: qso) }
        .alert("Delete this contact?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                context.delete(qso); try? context.save(); Haptics.warning(); dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func metric(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased()).font(Brand.mono(10, weight: .medium)).tracking(1).foregroundStyle(Brand.text3)
            Text(value).font(Brand.mono(18, weight: .semibold)).foregroundStyle(color)
        }
    }
    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Brand.text3)
            Spacer()
            Text(value).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
        }
    }
}

/// A small compass rose with a needle pointing along the bearing.
struct CompassRose: View {
    let bearing: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        ZStack {
            Circle().strokeBorder(Brand.hairline, lineWidth: 1.5)
            ForEach(0..<4) { i in
                Text(["N","E","S","W"][i])
                    .font(Brand.mono(9, weight: .bold)).foregroundStyle(Brand.text3)
                    .offset(y: -32).rotationEffect(.degrees(Double(i) * 90))
            }
            Image(systemName: "location.north.fill")
                .font(.system(size: 22)).foregroundStyle(Brand.info)
                .rotationEffect(.degrees(bearing))
                .animation(reduceMotion ? nil : Brand.ease(), value: bearing)
        }
        .frame(width: 84, height: 84)
        .accessibilityHidden(true)
    }
}

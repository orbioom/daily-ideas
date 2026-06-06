import SwiftUI
import SwiftData

/// A standalone Maidenhead calculator: distance and bearing between two grids.
struct GridToolsView: View {
    @AppStorage("myGrid") private var myGrid = ""
    @AppStorage("distanceUnit") private var unitRaw = DistanceUnit.km.rawValue
    @Query private var qsos: [QSO]

    @State private var fromGrid = ""
    @State private var toGrid = ""
    @FocusState private var focused: Field?
    private enum Field { case from, to }

    private var unit: DistanceUnit { DistanceUnit(rawValue: unitRaw) ?? .km }
    private var fromValid: Bool { GridMath.normalize(fromGrid) != nil }
    private var toValid: Bool { GridMath.normalize(toGrid) != nil }

    private var result: (dist: String, bearing: Double, compass: String)? {
        guard let km = GridMath.distanceKm(from: fromGrid, to: toGrid),
              let b = GridMath.bearing(from: fromGrid, to: toGrid) else { return nil }
        return (unit.format(km: km), b, GridMath.compass(b))
    }

    /// Distinct 4-char grids worked, sorted, for a quick reference list.
    private var workedGrids: [String] {
        Array(Set(qsos.map { String($0.theirGrid.prefix(4)) }.filter { $0.count == 4 })).sorted()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 14) {
                        Eyebrow(text: "Distance & bearing")
                        gridField("From", text: $fromGrid, valid: fromValid || fromGrid.isEmpty, focus: .from)
                        HStack {
                            Spacer()
                            Button {
                                let t = fromGrid; fromGrid = toGrid; toGrid = t; Haptics.selection()
                            } label: {
                                Image(systemName: "arrow.up.arrow.down").font(.subheadline)
                                    .foregroundStyle(Brand.text2)
                            }
                            .accessibilityLabel("Swap grids")
                            Spacer()
                        }
                        gridField("To", text: $toGrid, valid: toValid || toGrid.isEmpty, focus: .to)
                        if !myGrid.isEmpty {
                            Button("Use my grid (\(myGrid)) as From") { fromGrid = myGrid; Haptics.tap() }
                                .font(.footnote).foregroundStyle(Brand.info)
                        }
                    }
                    .glassCard(padding: 20)

                    if let r = result {
                        VStack(spacing: 16) {
                            CompassRose(bearing: r.bearing).scaleEffect(1.3).frame(height: 120)
                            HStack(spacing: 12) {
                                StatTile(value: r.dist, label: "Distance", accent: Brand.text)
                                StatTile(value: "\(Int(r.bearing.rounded()))°", label: r.compass, accent: Brand.info)
                            }
                        }
                    } else if fromValid || toValid {
                        Text("Enter two valid grids (e.g. FN31 and IO91) to compute the path.")
                            .font(.subheadline).foregroundStyle(Brand.text2)
                            .frame(maxWidth: .infinity, alignment: .leading).glassCard()
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Eyebrow(text: "How it works")
                            Text("A Maidenhead locator like FN31pr pins a spot on Earth. Beacon decodes two of them and measures the great-circle path between their centers — the same math used on the air.")
                                .font(.subheadline).foregroundStyle(Brand.text2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).glassCard()
                    }

                    if !workedGrids.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Eyebrow(text: "Grids worked (\(workedGrids.count))")
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                                ForEach(workedGrids, id: \.self) { g in
                                    Text(g).font(Brand.mono(13)).foregroundStyle(Brand.text)
                                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                                        .onTapGesture { toGrid = g; Haptics.selection() }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)
                    }
                }
                .padding(16)
            }
            .background(Brand.pageBackground)
            .navigationTitle("Grid Tools")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer(); Button("Done") { focused = nil }
                }
            }
        }
    }

    private func gridField(_ label: String, text: Binding<String>, valid: Bool, focus: Field) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased()).font(Brand.mono(11, weight: .medium)).tracking(1).foregroundStyle(Brand.text3)
            TextField("FN31pr", text: text)
                .textInputAutocapitalization(.characters).autocorrectionDisabled()
                .font(Brand.mono(22, weight: .semibold)).foregroundStyle(Brand.text)
                .focused($focused, equals: focus)
            if !valid {
                Text("Invalid locator").font(.caption).foregroundStyle(Brand.danger)
            }
        }
    }
}

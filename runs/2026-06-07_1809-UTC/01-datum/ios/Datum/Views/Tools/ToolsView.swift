import SwiftUI

/// The Tools tab: a density-altitude calculator, an ad-hoc CG calculator and a
/// quick unit reference. Everything updates live as you type.
struct ToolsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 16) {
                        DensityAltitudeCard()
                        AdHocCGCard()
                        UnitReferenceCard()
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Tools")
        }
    }
}

// MARK: - Density altitude

private struct DensityAltitudeCard: View {
    @State private var fieldElev = "0"
    @State private var altimeter = "29.92"
    @State private var oat = "15"

    private var computed: (pressureAlt: Double, densityAlt: Double) {
        WBEngine.densityAltitude(
            fieldElevFt: NumParse.any(fieldElev),
            altimeterInHg: NumParse.any(altimeter),
            oatC: NumParse.any(oat)
        )
    }

    private var note: String {
        let da = computed.densityAlt
        let elev = NumParse.any(fieldElev)
        let delta = da - elev
        if delta > 1500 {
            return "Density altitude is well above field elevation — expect noticeably reduced climb and longer takeoff rolls."
        } else if delta > 0 {
            return "Density altitude is above field elevation. Performance will be slightly degraded versus standard conditions."
        } else {
            return "Cooler or higher-pressure than standard — performance is at or better than field elevation."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow(text: "Density altitude")
            NumberField(label: "Field elevation (ft)", text: $fieldElev)
            NumberField(label: "Altimeter (inHg)", text: $altimeter)
            NumberField(label: "OAT (°C)", text: $oat)
            Divider().background(Brand.hairline)
            HStack(spacing: 10) {
                StatTile(value: Fmt.weight(computed.pressureAlt.rounded()), label: "Pressure alt ft", accent: Brand.info)
                StatTile(value: Fmt.weight(computed.densityAlt.rounded()), label: "Density alt ft",
                         accent: computed.densityAlt - NumParse.any(fieldElev) > 1500 ? Brand.warn : Brand.text)
            }
            Text(note)
                .font(.caption)
                .foregroundStyle(Brand.text3)
        }
        .glassCard()
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Ad-hoc CG

private struct AdHocRow: Identifiable {
    let id = UUID()
    var label: String = ""
    var weight: String = ""
    var arm: String = ""
}

private struct AdHocCGCard: View {
    @State private var rows: [AdHocRow] = [
        AdHocRow(label: "Item 1", weight: "", arm: ""),
        AdHocRow(label: "Item 2", weight: "", arm: "")
    ]

    private var point: WBEngine.Point {
        WBEngine.adHocCG(rows: rows.map {
            (weight: NumParse.nonNegative($0.weight), arm: NumParse.any($0.arm))
        })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Eyebrow(text: "Quick CG")
                Spacer()
                Button {
                    Haptics.tap()
                    rows.append(AdHocRow(label: "Item \(rows.count + 1)"))
                } label: {
                    Image(systemName: "plus.circle")
                }
                .accessibilityLabel("Add row")
            }
            if rows.isEmpty {
                Text("Add weight-at-arm rows to compute a combined weight and CG.")
                    .font(.subheadline).foregroundStyle(Brand.text2)
            } else {
                ForEach($rows) { $row in
                    HStack(spacing: 8) {
                        TextField("Label", text: $row.label)
                            .font(.subheadline)
                            .foregroundStyle(Brand.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        CompactNumberField(label: "Wt (lb)", text: $row.weight).frame(width: 80)
                        CompactNumberField(label: "Arm (in)", text: $row.arm).frame(width: 80)
                        Button {
                            Haptics.tap()
                            rows.removeAll { $0.id == row.id }
                        } label: {
                            Image(systemName: "minus.circle.fill").foregroundStyle(Brand.text3)
                        }
                        .accessibilityLabel("Remove \(row.label.isEmpty ? "row" : row.label)")
                    }
                }
            }
            Divider().background(Brand.hairline)
            HStack(spacing: 10) {
                StatTile(value: Fmt.weight(point.weight), label: "Total lb")
                StatTile(value: point.weight > 0 ? Fmt.arm(point.cg) : "—", label: "CG in",
                         accent: Brand.info)
            }
            if point.weight <= 0 {
                Text("Enter at least one weight to compute the CG.")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
        }
        .glassCard()
    }
}

// MARK: - Unit reference

private struct UnitReferenceCard: View {
    @State private var poundsText = "100"

    private var lb: Double { NumParse.nonNegative(poundsText) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow(text: "Unit reference")
            NumberField(label: "Pounds (lb)", text: $poundsText)
            InfoRow(label: "Kilograms", value: String(format: "%.1f kg", Fmt.lbToKg(lb)), mono: true)
            Divider().background(Brand.hairline)
            VStack(alignment: .leading, spacing: 6) {
                refLine("1 lb", "0.4536 kg")
                refLine("1 in", "2.54 cm")
                refLine("100LL / Mogas", "≈ 6.0 lb/gal")
                refLine("Jet-A", "≈ 6.7 lb/gal")
            }
            Text("Arm is the horizontal distance from the datum; moment = weight × arm.")
                .font(.caption).foregroundStyle(Brand.text3)
        }
        .glassCard()
    }

    private func refLine(_ a: String, _ b: String) -> some View {
        HStack {
            Text(a).font(Brand.mono(12, weight: .medium)).foregroundStyle(Brand.text2)
            Spacer()
            Text(b).font(Brand.mono(12)).foregroundStyle(Brand.text3)
        }
    }
}

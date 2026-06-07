import SwiftUI

/// Cone temperature reference and a clay shrinkage calculator.
struct ReferenceView: View {
    @AppStorage("cone.celsius") private var celsius = false
    @State private var shrinkage = 12.0      // % total shrinkage wet → fired
    @State private var desiredFired = 20.0   // cm finished size wanted

    private var wetSize: Double {
        // fired = wet * (1 - shrink/100)  →  wet = fired / (1 - shrink/100)
        let f = 1 - shrinkage / 100
        return f > 0 ? desiredFired / f : 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    shrinkageCard
                    coneCard
                    Text("Cone temperatures are approximate Orton self-supporting values. Always confirm with witness cones.")
                        .font(.caption2).foregroundStyle(Brand.text3).multilineTextAlignment(.center)
                }
                .padding()
            }
            .navigationTitle("Reference")
            .background(Brand.pageBackground)
        }
    }

    private var shrinkageCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(text: "Shrinkage calculator")
            HStack {
                Text("Total shrinkage").foregroundStyle(Brand.text2)
                Spacer()
                Text("\(String(format: "%.1f", shrinkage))%").font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.text)
            }
            Slider(value: $shrinkage, in: 4...20, step: 0.5).tint(Brand.live)
            HStack {
                Text("Desired fired size").foregroundStyle(Brand.text2)
                Spacer()
                Stepper("\(String(format: "%.1f", desiredFired)) cm", value: $desiredFired, in: 1...80, step: 0.5).fixedSize()
            }
            Divider().overlay(Brand.hairline)
            HStack {
                Text("Make it this wet").font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text2)
                Spacer()
                Text("\(String(format: "%.1f", wetSize)) cm").font(Brand.mono(22, weight: .bold)).foregroundStyle(Brand.live)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Throw at \(String(format: "%.1f", wetSize)) centimetres for a \(String(format: "%.1f", desiredFired)) centimetre fired piece")
            .font(.subheadline)
        }
        .glassCard()
    }

    private var coneCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionTitle(text: "Cone temperatures")
                Spacer()
                Text(celsius ? "°C" : "°F").font(Brand.mono(12, weight: .medium)).foregroundStyle(Brand.text3)
            }
            HStack {
                Text("Cone").frame(width: 60, alignment: .leading)
                Text("108°/hr").frame(maxWidth: .infinity, alignment: .trailing)
                Text("270°/hr").frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(Brand.mono(10, weight: .medium)).foregroundStyle(Brand.text3)
            ForEach(ConeMath.coneTable) { c in
                HStack {
                    Text("△\(c.cone)").frame(width: 60, alignment: .leading).foregroundStyle(Brand.text)
                    Text(ConeMath.formatTemp(c.slowF, celsius: celsius)).frame(maxWidth: .infinity, alignment: .trailing).foregroundStyle(Brand.text2)
                    Text(ConeMath.formatTemp(c.fastF, celsius: celsius)).frame(maxWidth: .infinity, alignment: .trailing).foregroundStyle(Brand.text2)
                }
                .font(Brand.mono(13))
                if c.id != ConeMath.coneTable.last?.id { Divider().overlay(Brand.hairline) }
            }
        }
        .glassCard()
    }
}

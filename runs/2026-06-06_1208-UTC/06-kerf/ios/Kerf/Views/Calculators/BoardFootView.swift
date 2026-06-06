import SwiftUI

/// Board-foot calculator (imperial: thickness & width in inches, length in inches).
struct BoardFootView: View {
    @State private var thickness = "1"
    @State private var width = "6"
    @State private var lengthFeet = "8"
    @State private var quantity = 1
    @State private var pricePerBF = ""

    private var lengthInches: Double { (parse(lengthFeet)) * 12 }
    private var boardFeet: Double {
        BoardFoot.feet(thicknessIn: parse(thickness), widthIn: parse(width), lengthIn: lengthInches, quantity: quantity)
    }
    private var cost: Double { boardFeet * parse(pricePerBF) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                inputCard
                resultCard
                Text("1 board foot = 144 cubic inches (a 1\" × 12\" × 12\" piece). Thickness uses nominal rough size.")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
            .padding(.horizontal, 16).padding(.vertical, 8).padding(.bottom, 28)
        }
        .background(Brand.pageBackground)
        .navigationTitle("Board Feet").navigationBarTitleDisplayMode(.inline)
    }

    private var inputCard: some View {
        VStack(spacing: 14) {
            field("Thickness (in)", $thickness)
            field("Width (in)", $width)
            field("Length (ft)", $lengthFeet)
            Stepper(value: $quantity, in: 1...999) {
                HStack { Text("Quantity").font(.subheadline).foregroundStyle(Brand.text); Spacer()
                    Text("\(quantity)").font(Brand.mono(15)).foregroundStyle(Brand.text2) }
            }
            Divider().overlay(Brand.hairline)
            field("Price per board-ft (optional)", $pricePerBF)
        }
        .glassCard()
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Result")
            HStack(spacing: 10) {
                StatTile(value: String(format: "%.2f", boardFeet), label: "Board feet", tint: Brand.live)
                if cost > 0 { StatTile(value: String(format: "%.2f", cost), label: "Est. cost") }
            }
            if boardFeet > 0 {
                Text("\(quantity) piece\(quantity == 1 ? "" : "s") at \(parse(thickness).clean)\" × \(parse(width).clean)\" × \(parse(lengthFeet).clean) ft.")
                    .font(.footnote).foregroundStyle(Brand.text2)
            } else {
                Text("Enter dimensions to calculate.").font(.subheadline).foregroundStyle(Brand.text2)
            }
        }
        .glassCard()
    }

    private func field(_ label: String, _ binding: Binding<String>) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Brand.text)
            Spacer()
            TextField("0", text: binding).keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing).frame(width: 90).font(Brand.mono(16))
        }
    }
    private func parse(_ s: String) -> Double { max(0, Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0) }
}

private extension Double {
    var clean: String { self == rounded() ? String(Int(self)) : String(format: "%.2f", self) }
}

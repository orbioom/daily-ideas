import SwiftUI

struct UnitConverterCard: View {
    @State private var tempInput = "400"
    @State private var tempFromF = true   // true: F→C, false: C→F

    @State private var weightInput = "250"
    @State private var weightFromG = true // true: g→oz, false: oz→g

    var body: some View {
        VStack(spacing: 16) {
            tempCard
            weightCard
        }
    }

    // MARK: Temperature

    private var tempCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Temperature", systemImage: "thermometer.medium")
                .font(Theme.roundedStyle(.headline, .bold))
                .foregroundStyle(Theme.ink)
            Picker("Direction", selection: $tempFromF) {
                Text("°F → °C").tag(true)
                Text("°C → °F").tag(false)
            }
            .pickerStyle(.segmented)
            HStack(spacing: 10) {
                TextField("0", text: $tempInput)
                    .keyboardType(.numbersAndPunctuation)
                    .font(Theme.roundedStyle(.title2, .bold))
                    .foregroundStyle(Theme.ink)
                    .padding(12)
                    .crispCard(radius: Theme.chipRadius)
                Image(systemName: "equal")
                    .foregroundStyle(Theme.inkSoft)
                    .accessibilityHidden(true)
                Text(tempResult)
                    .font(Theme.roundedStyle(.title2, .bold))
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .crispCard(radius: Theme.chipRadius)
            }
        }
        .padding(16)
        .crispCard()
    }

    private var tempResult: String {
        guard let v = Double(tempInput.replacingOccurrences(of: ",", with: ".")) else { return "—" }
        if tempFromF {
            let c = ConversionEngine.fahrenheitToCelsius(v)
            return String(format: "%.0f°C", c.rounded())
        } else {
            let f = ConversionEngine.celsiusToFahrenheit(v)
            return String(format: "%.0f°F", f.rounded())
        }
    }

    // MARK: Weight

    private var weightCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Weight", systemImage: "scalemass")
                .font(Theme.roundedStyle(.headline, .bold))
                .foregroundStyle(Theme.ink)
            Picker("Direction", selection: $weightFromG) {
                Text("g → oz").tag(true)
                Text("oz → g").tag(false)
            }
            .pickerStyle(.segmented)
            HStack(spacing: 10) {
                TextField("0", text: $weightInput)
                    .keyboardType(.decimalPad)
                    .font(Theme.roundedStyle(.title2, .bold))
                    .foregroundStyle(Theme.ink)
                    .padding(12)
                    .crispCard(radius: Theme.chipRadius)
                Image(systemName: "equal")
                    .foregroundStyle(Theme.inkSoft)
                    .accessibilityHidden(true)
                Text(weightResult)
                    .font(Theme.roundedStyle(.title2, .bold))
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .crispCard(radius: Theme.chipRadius)
            }
        }
        .padding(16)
        .crispCard()
    }

    private var weightResult: String {
        guard let v = Double(weightInput.replacingOccurrences(of: ",", with: ".")), v >= 0 else { return "—" }
        if weightFromG {
            let oz = ConversionEngine.gramsToOunces(v)
            return String(format: "%.1f oz", oz)
        } else {
            let g = ConversionEngine.ouncesToGrams(v)
            return String(format: "%.0f g", g.rounded())
        }
    }
}

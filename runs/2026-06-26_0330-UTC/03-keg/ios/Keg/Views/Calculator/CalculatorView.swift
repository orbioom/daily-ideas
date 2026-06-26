import SwiftUI

struct CalculatorView: View {
    @State private var selectedCalc = 0
    let calcs = ["ABV", "Priming", "Strike", "Refract"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Calculator", selection: $selectedCalc) {
                    ForEach(0..<calcs.count, id: \.self) { i in
                        Text(calcs[i]).tag(i)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                ScrollView {
                    Group {
                        switch selectedCalc {
                        case 0: ABVCalcView()
                        case 1: PrimingCalcView()
                        case 2: StrikeWaterCalcView()
                        case 3: RefractometerCalcView()
                        default: ABVCalcView()
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Calculators")
        }
    }
}

// MARK: - ABV Calculator

struct ABVCalcView: View {
    @State private var og: Double = 1.050
    @State private var fg: Double = 1.010

    var abv: Double { (og - fg) * 131.25 }
    var attenuation: Double {
        let ogP = (og - 1.0) * 1000
        let fgP = (fg - 1.0) * 1000
        guard ogP > 0 else { return 0 }
        return (1.0 - fgP / ogP) * 100
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ABV from Original & Final Gravity")
                    .font(.headline)
                Text("Uses the standard formula: (OG − FG) × 131.25")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            GravitySliderRow(label: "Original Gravity (OG)", value: $og, range: 1.020...1.120, step: 0.001)
            GravitySliderRow(label: "Final Gravity (FG)", value: $fg, range: 1.000...1.050, step: 0.001)

            HStack(spacing: 12) {
                ResultTile(label: "ABV", value: String(format: "%.2f%%", abv), color: KegTheme.accent)
                ResultTile(label: "Attenuation", value: String(format: "%.0f%%", max(0, attenuation)), color: .green)
            }
        }
    }
}

// MARK: - Priming Sugar Calculator

struct PrimingCalcView: View {
    @State private var beerVolumeLiters: Double = 19
    @State private var targetCO2: Double = 2.4
    @State private var beerTempC: Double = 20
    @State private var sugarType = 0
    let sugarTypes = ["Corn Sugar (Dextrose)", "Table Sugar (Sucrose)", "DME"]
    let sugarFactors = [4.0, 3.8, 5.33] // g per L per vol CO2 (approximate)

    var residualCO2: Double {
        // Approximation: CO2 dissolved in beer based on temp
        // Using Balling's equation approximation
        let t = beerTempC
        return max(0, 0.003 * t * t - 0.25 * t + 5.2)
    }

    var co2ToAdd: Double { max(0, targetCO2 - residualCO2) }
    var sugarGrams: Double { co2ToAdd * beerVolumeLiters * sugarFactors[sugarType] / (targetCO2 > 0 ? 1 : 1) }

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Priming Sugar for Bottle Carbonation")
                    .font(.headline)
                Text("Calculates sugar needed to reach target CO₂ volumes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Beer Volume")
                    Spacer()
                    Text(String(format: "%.0f L", beerVolumeLiters)).foregroundStyle(KegTheme.accent)
                }
                Slider(value: $beerVolumeLiters, in: 5...60, step: 1).tint(KegTheme.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Target CO₂ Volumes")
                    Spacer()
                    Text(String(format: "%.1f vol", targetCO2)).foregroundStyle(KegTheme.accent)
                }
                Slider(value: $targetCO2, in: 1.5...4.0, step: 0.1).tint(KegTheme.accent)
                Text("Ale: 2.2–2.8 | Wheat: 3.0–3.5 | Lager: 2.5–3.0")
                    .font(.caption2).foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Beer Temperature")
                    Spacer()
                    Text(String(format: "%.0f°C", beerTempC)).foregroundStyle(Color(red: 0.2, green: 0.6, blue: 0.9))
                }
                Slider(value: $beerTempC, in: 0...30, step: 1).tint(Color(red: 0.2, green: 0.6, blue: 0.9))
            }

            Picker("Sugar Type", selection: $sugarType) {
                ForEach(0..<sugarTypes.count, id: \.self) { i in
                    Text(sugarTypes[i]).tag(i)
                }
            }
            .pickerStyle(.menu)

            HStack(spacing: 12) {
                ResultTile(label: "Sugar Needed", value: String(format: "%.0f g", max(0, sugarGrams)), color: KegTheme.accent)
                ResultTile(label: "Residual CO₂", value: String(format: "%.2f vol", residualCO2), color: .orange)
            }
        }
    }
}

// MARK: - Strike Water Temperature

struct StrikeWaterCalcView: View {
    @State private var grainWeightKg: Double = 4.5
    @State private var waterLiters: Double = 15
    @State private var grainTempC: Double = 20
    @State private var targetMashTempC: Double = 68

    // Palmer's formula: Strike Water Temp = (0.41/r)(T2 - T1) + T2
    // r = water/grain ratio by weight
    var strikeTemp: Double {
        guard grainWeightKg > 0 else { return targetMashTempC }
        let r = waterLiters / grainWeightKg // L/kg ≈ qt/lb approximately for rough calc
        return (0.41 / r) * (targetMashTempC - grainTempC) + targetMashTempC
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Strike Water Temperature")
                    .font(.headline)
                Text("Uses Palmer's formula to hit your target mash temperature.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Grain Weight")
                    Spacer()
                    Text(String(format: "%.1f kg", grainWeightKg)).foregroundStyle(KegTheme.accent)
                }
                Slider(value: $grainWeightKg, in: 1...15, step: 0.1).tint(KegTheme.accent)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Strike Water Volume")
                    Spacer()
                    Text(String(format: "%.0f L", waterLiters)).foregroundStyle(Color(red: 0.2, green: 0.6, blue: 0.9))
                }
                Slider(value: $waterLiters, in: 5...40, step: 0.5).tint(Color(red: 0.2, green: 0.6, blue: 0.9))
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Grain Temp")
                    Spacer()
                    Text(String(format: "%.0f°C", grainTempC)).foregroundStyle(.secondary)
                }
                Slider(value: $grainTempC, in: 5...30, step: 1).tint(.gray)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Target Mash Temp")
                    Spacer()
                    Text(String(format: "%.0f°C", targetMashTempC)).foregroundStyle(.orange)
                }
                Slider(value: $targetMashTempC, in: 60...78, step: 0.5).tint(.orange)
                Text("Typical: 64–68°C for dry/fermentable, 68–72°C for full/sweet")
                    .font(.caption2).foregroundStyle(.secondary)
            }

            ResultTile(label: "Strike Water Temp", value: String(format: "%.1f°C", strikeTemp), color: .orange)
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Refractometer Correction

struct RefractometerCalcView: View {
    @State private var originalBrix: Double = 13.0
    @State private var currentBrix: Double = 7.0

    // Terrill's formula for refractometer FG correction
    var correctedFG: Double {
        let og = originalBrix / 4.0 + 1.0 // Rough OG from Brix
        // Terrill: FG = 1.0000 - 0.0044993 * Ri + 0.011774 * Rf + 0.00027581 * Ri² - 0.0012717 * Rf² - 0.0000072800 * Ri³ + 0.000063293 * Rf³
        let ri = originalBrix
        let rf = currentBrix
        return 1.0000 - 0.0044993 * ri + 0.011774 * rf + 0.00027581 * ri * ri - 0.0012717 * rf * rf - 0.0000072800 * ri * ri * ri + 0.000063293 * rf * rf * rf
    }

    var ogFromBrix: Double { (originalBrix / 4.0) + 1.0 }
    var estimatedABV: Double { max(0, (ogFromBrix - correctedFG) * 131.25) }

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Refractometer Correction")
                    .font(.headline)
                Text("Corrects Brix readings during active fermentation using Terrill's formula.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Original Brix (pre-ferment)")
                    Spacer()
                    Text(String(format: "%.1f°Bx", originalBrix)).foregroundStyle(KegTheme.accent)
                }
                Slider(value: $originalBrix, in: 5...30, step: 0.1).tint(KegTheme.accent)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Current Brix (fermenting)")
                    Spacer()
                    Text(String(format: "%.1f°Bx", currentBrix)).foregroundStyle(.purple)
                }
                Slider(value: $currentBrix, in: 1...30, step: 0.1).tint(.purple)
            }

            HStack(spacing: 12) {
                ResultTile(label: "Corrected FG", value: correctedFG.gravityDisplay, color: .purple)
                ResultTile(label: "Est. ABV", value: String(format: "%.2f%%", estimatedABV), color: KegTheme.accent)
            }
        }
    }
}

struct ResultTile: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

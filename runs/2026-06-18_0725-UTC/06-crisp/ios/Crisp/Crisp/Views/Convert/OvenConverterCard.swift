import SwiftUI

struct OvenConverterCard: View {
    @EnvironmentObject private var settings: AppSettings

    @State private var ovenTempText = "425"
    @State private var ovenMinutesText = "30"

    private var ovenTemp: Int? { Int(ovenTempText.trimmingCharacters(in: .whitespaces)) }
    private var ovenMinutes: Int? { Int(ovenMinutesText.trimmingCharacters(in: .whitespaces)) }

    private var result: ConversionEngine.OvenToAirFryer? {
        guard let t = ovenTemp, let m = ovenMinutes, t > 0, m > 0 else { return nil }
        return ConversionEngine.ovenToAirFryer(ovenTempF: t, ovenMinutes: m)
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 14) {
                Label("Oven recipe", systemImage: "oven")
                    .font(Theme.roundedStyle(.headline, .bold))
                    .foregroundStyle(Theme.ink)
                numberRow(title: "Oven temperature (°F)", text: $ovenTempText, prompt: "425")
                numberRow(title: "Oven time (minutes)", text: $ovenMinutesText, prompt: "30")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .crispCard()

            if let r = result {
                resultCard(r)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.inkSoft)
                        .accessibilityHidden(true)
                    Text("Enter a valid oven temp and time to see the air-fryer setting.")
                        .font(Theme.roundedStyle(.subheadline))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .crispCard()
            }

            ruleCard
        }
    }

    private func numberRow(title: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Theme.roundedStyle(.subheadline, .medium))
                .foregroundStyle(Theme.inkSoft)
            TextField(prompt, text: text)
                .keyboardType(.numberPad)
                .font(Theme.roundedStyle(.title3, .bold))
                .foregroundStyle(Theme.ink)
                .padding(12)
                .crispCard(radius: Theme.chipRadius)
        }
    }

    private func resultCard(_ r: ConversionEngine.OvenToAirFryer) -> some View {
        VStack(spacing: 14) {
            Label("Air-fryer setting", systemImage: "wind")
                .font(Theme.roundedStyle(.headline, .bold))
                .foregroundStyle(Theme.accent)
            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("\(Fmt.tempValue(fahrenheit: r.airFryerTempF, unit: settings.tempUnit))°")
                        .font(Theme.rounded(44, .bold))
                        .foregroundStyle(Theme.ink)
                        .monospacedDigit()
                    Text(settings.tempUnit == .fahrenheit ? "Fahrenheit" : "Celsius")
                        .font(Theme.roundedStyle(.caption))
                        .foregroundStyle(Theme.inkSoft)
                }
                Rectangle().fill(Theme.hairline).frame(width: 1, height: 56)
                VStack(spacing: 2) {
                    Text("\(r.airFryerMinutes)")
                        .font(Theme.rounded(44, .bold))
                        .foregroundStyle(Theme.ink)
                        .monospacedDigit()
                    Text("minutes")
                        .font(Theme.roundedStyle(.caption))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            Text("Check 3–4 minutes early the first time — fryers vary.")
                .font(Theme.roundedStyle(.caption))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .crispCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Air-fryer setting: \(Fmt.temp(fahrenheit: r.airFryerTempF, unit: settings.tempUnit)) for \(r.airFryerMinutes) minutes")
    }

    private var ruleCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Rule of thumb: drop the temperature 25°F and cut the time by about 20%.")
                .font(Theme.roundedStyle(.footnote))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(14)
        .crispCard(radius: Theme.chipRadius)
        .accessibilityElement(children: .combine)
    }
}

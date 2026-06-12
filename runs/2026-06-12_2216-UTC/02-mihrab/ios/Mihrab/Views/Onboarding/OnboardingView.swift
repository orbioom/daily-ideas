import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("cityID") private var cityID = Gazetteer.defaultCityID
    @AppStorage("method") private var methodRaw = CalculationMethod.mwl.rawValue
    @Environment(\.colorScheme) private var colorScheme

    @State private var step = 0

    var body: some View {
        ZStack {
            MihrabTheme.skyGradient(colorScheme).ignoresSafeArea()
            VStack(spacing: 0) {
                if step == 0 {
                    welcome
                } else {
                    setup
                }
            }
        }
    }

    private var welcome: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 56))
                .foregroundStyle(MihrabTheme.gold)
                .accessibilityHidden(true)
            Text("Mihrab")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(.white)
            Text("Prayer times, qibla, and a private prayer tracker — computed entirely on your iPhone.\n\nNo account. No location permission. No ads. Your worship is not a product.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 32)
            Spacer()
            Button {
                Haptics.tap()
                withAnimation { step = 1 }
            } label: {
                Text("Set Up")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(MihrabTheme.gold)
            .foregroundStyle(.black)
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
    }

    private var setup: some View {
        VStack(spacing: 16) {
            Text("Your City & Method")
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.top, 32)
            Text("Pick the city you pray in and the convention your community follows. Both can be changed anytime in Settings.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.75))
                .padding(.horizontal, 28)

            Form {
                Section("City") {
                    Picker("City", selection: $cityID) {
                        ForEach(Gazetteer.cities.sorted(by: { $0.name < $1.name })) { city in
                            Text(city.displayName).tag(city.id)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section("Calculation method") {
                    Picker("Method", selection: $methodRaw) {
                        ForEach(CalculationMethod.allCases) { method in
                            Text(method.displayName).tag(method.rawValue)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .scrollContentBackground(.hidden)

            Button {
                Haptics.success()
                hasOnboarded = true
            } label: {
                Text("Begin")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(MihrabTheme.gold)
            .foregroundStyle(.black)
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
    }
}

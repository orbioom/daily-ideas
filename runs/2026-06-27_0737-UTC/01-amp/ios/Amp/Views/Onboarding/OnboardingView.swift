import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Bindable var settings: AmpSettings
    @Environment(\.modelContext) private var context
    @State private var page = 0

    var body: some View {
        ZStack {
            AmpTheme.gradient()
                .ignoresSafeArea()
            TabView(selection: $page) {
                WelcomePage().tag(0)
                UnitPage(settings: settings).tag(1)
                ReadyPage(settings: settings).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
        }
        .onAppear {
            if (try? context.fetch(FetchDescriptor<AmpSettings>()))?.first == nil {
                context.insert(settings)
            }
        }
    }
}

private struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "bolt.batteryblock.fill")
                .font(.system(size: 80))
                .foregroundStyle(.white)
            Text("Amp")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("Track every charge.\nUnderstand your EV.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(40)
    }
}

private struct UnitPage: View {
    @Bindable var settings: AmpSettings
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "gauge.with.dots.needle.33percent")
                .font(.system(size: 60))
                .foregroundStyle(.white)
            Text("Your Preferences")
                .font(.title).bold()
                .foregroundStyle(.white)
            VStack(spacing: 16) {
                Toggle("Use miles & gallons", isOn: $settings.useImperial)
                    .toggleStyle(.switch)
                    .tint(.white)
                    .foregroundStyle(.white)
                Divider().background(.white.opacity(0.3))
                HStack {
                    Text("Currency").foregroundStyle(.white)
                    Spacer()
                    Picker("", selection: $settings.currencySymbol) {
                        Text("$ USD").tag("$")
                        Text("€ EUR").tag("€")
                        Text("£ GBP").tag("£")
                        Text("¥ JPY").tag("¥")
                        Text("C$ CAD").tag("C$")
                    }
                    .pickerStyle(.menu)
                    .tint(.white)
                }
                Divider().background(.white.opacity(0.3))
                HStack {
                    Text("Gas price").foregroundStyle(.white)
                    Spacer()
                    TextField("3.80", value: $settings.fuelCostPerUnit, format: .number)
                        .keyboardType(.decimalPad)
                        .foregroundStyle(.white)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                    Text(settings.useImperial ? "/gal" : "/L").foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(20)
            .background(.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(40)
    }
}

private struct ReadyPage: View {
    @Bindable var settings: AmpSettings
    @Environment(\.modelContext) private var context
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 70))
                .foregroundStyle(.white)
            Text("You're all set!")
                .font(.title).bold()
                .foregroundStyle(.white)
            Text("Log your first charge and start seeing insights about your EV.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal)
            Button {
                withAnimation {
                    settings.hasCompletedOnboarding = true
                    try? context.save()
                }
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white)
                    .foregroundStyle(Color("AmpBlue"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 40)
        }
        .padding(40)
    }
}

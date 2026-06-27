import SwiftUI
import SwiftData

struct StrokeOnboardingView: View {
    @Bindable var settings: StrokeSettings
    @Environment(\.modelContext) private var context
    @State private var page = 0

    var body: some View {
        ZStack {
            StrokeTheme.gradient().ignoresSafeArea()
            TabView(selection: $page) {
                page0.tag(0)
                page1.tag(1)
                page2.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
        }
    }

    private var page0: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.rowing")
                .font(.system(size: 80))
                .foregroundStyle(.white)
            Text("Stroke")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("Your rowing erg\nlog & analytics.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(40)
    }

    private var page1: some View {
        VStack(spacing: 28) {
            Image(systemName: "gauge.with.dots.needle.67percent")
                .font(.system(size: 60))
                .foregroundStyle(.white)
            Text("Your Profile")
                .font(.title.bold())
                .foregroundStyle(.white)
            VStack(spacing: 16) {
                HStack {
                    Text("Body weight").foregroundStyle(.white)
                    Spacer()
                    TextField("75", value: $settings.weightKg, format: .number)
                        .keyboardType(.decimalPad)
                        .foregroundStyle(.white)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                    Text("kg").foregroundStyle(.white.opacity(0.8))
                }
                Divider().background(.white.opacity(0.3))
                HStack {
                    Text("Weekly goal").foregroundStyle(.white)
                    Spacer()
                    Picker("", selection: $settings.weeklyDistanceGoalM) {
                        Text("10 km").tag(10000)
                        Text("20 km").tag(20000)
                        Text("30 km").tag(30000)
                        Text("50 km").tag(50000)
                    }
                    .pickerStyle(.menu)
                    .tint(.white)
                }
                Divider().background(.white.opacity(0.3))
                Toggle("Show watts", isOn: $settings.displayWatts)
                    .foregroundStyle(.white)
                    .tint(.white)
            }
            .padding(20)
            .background(.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(40)
    }

    private var page2: some View {
        VStack(spacing: 32) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 70))
                .foregroundStyle(.white)
            Text("Ready to row!")
                .font(.title.bold())
                .foregroundStyle(.white)
            Text("Log every piece.\nTrack every split.\nCrush every PR.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.85))
            Button {
                settings.hasCompletedOnboarding = true
                try? context.save()
            } label: {
                Text("Let's Go")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white)
                    .foregroundStyle(Color("StrokeTeal"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 40)
        }
        .padding(40)
    }
}

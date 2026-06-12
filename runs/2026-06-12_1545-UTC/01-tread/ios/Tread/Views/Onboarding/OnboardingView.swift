import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("dailyGoal") private var dailyGoal = 10_000
    @Environment(PedometerService.self) private var pedometer
    @State private var page = 0

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("figure.walk.motion", "Every step counts",
         "Tread turns your iPhone's built-in motion sensor into a calm, honest step tracker. No account, no ads, no subscription to see your own numbers."),
        ("rosette", "Build a streak you're proud of",
         "Set a daily goal, keep the ring closing, and earn milestone badges from your first 10K day to a 30-day streak."),
        ("lock.shield", "Your activity stays yours",
         "Steps are read on-device and stored only on your iPhone. Tread never uploads a single step.")
    ]

    var body: some View {
        ZStack {
            Theme.bgPrimary.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        VStack(spacing: 22) {
                            Spacer()
                            Image(systemName: pages[i].symbol)
                                .font(.system(size: 78))
                                .foregroundStyle(Theme.accent)
                                .accessibilityHidden(true)
                            Text(pages[i].title)
                                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Theme.textPrimary)
                            Text(pages[i].body)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Theme.textSecondary)
                                .padding(.horizontal, 32)
                            Spacer()
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                if page == pages.count - 1 {
                    VStack(spacing: 14) {
                        GoalPickerInline(goal: $dailyGoal)
                            .padding(.horizontal)
                        Button {
                            Haptics.success()
                            pedometer.start()      // triggers the motion permission prompt
                            hasOnboarded = true
                        } label: {
                            Text("Start walking")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.accent)
                        .controlSize(.large)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 30)
                    .transition(.opacity)
                } else {
                    Button("Continue") { withAnimation { page += 1 } }
                        .font(.headline)
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.accent)
                        .controlSize(.large)
                        .padding(.bottom, 30)
                }
            }
        }
    }
}

struct GoalPickerInline: View {
    @Binding var goal: Int
    private let options = [6_000, 8_000, 10_000, 12_000, 15_000]

    var body: some View {
        VStack(spacing: 8) {
            Text("Daily goal")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { value in
                    Button {
                        Haptics.tap(); goal = value
                    } label: {
                        Text("\(value / 1000)K")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(goal == value ? Theme.accent : Theme.track,
                                        in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(goal == value ? .white : Theme.textPrimary)
                    }
                    .accessibilityAddTraits(goal == value ? [.isSelected] : [])
                }
            }
        }
    }
}

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Query private var settings: [NourishSettings]
    @Environment(\.modelContext) private var context
    @State private var page = 0
    @State private var selectedGoal: PrimaryGoal = .elimination

    private var currentSettings: NourishSettings? { settings.first }

    var body: some View {
        TabView(selection: $page) {
            page1.tag(0)
            page2.tag(1)
            page3.tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .background(NourishTheme.background.ignoresSafeArea())
        .animation(.easeInOut, value: page)
    }

    private var page1: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(NourishTheme.sage)
            Text("Nourish")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(NourishTheme.charcoal)
            Text("Track every meal and symptom to uncover which foods your body loves — and which ones don't love you back.")
                .font(.body)
                .foregroundStyle(NourishTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button { withAnimation { page = 1 } } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(NourishTheme.sage, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 48)
        }
    }

    private var page2: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "flask.fill")
                .font(.system(size: 64))
                .foregroundStyle(NourishTheme.terra)
            Text("Choose Your Goal")
                .font(.title.weight(.bold))
            VStack(spacing: 12) {
                ForEach(PrimaryGoal.allCases) { goal in
                    GoalRow(goal: goal, isSelected: selectedGoal == goal) {
                        selectedGoal = goal
                    }
                }
            }
            .padding(.horizontal, 24)
            Spacer()
            Button { withAnimation { page = 2 } } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(NourishTheme.sage, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 48)
        }
    }

    private var page3: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "brain.head.profile")
                .font(.system(size: 64))
                .foregroundStyle(NourishTheme.corn)
            Text("Smart Correlations")
                .font(.title.weight(.bold))
            Text("Nourish looks for patterns between what you eat and how you feel — up to 48 hours later.")
                .font(.body)
                .foregroundStyle(NourishTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            VStack(alignment: .leading, spacing: 10) {
                FeatureRow(icon: "fork.knife", text: "Log every meal in seconds")
                FeatureRow(icon: "waveform.path.ecg", text: "Track symptoms with severity")
                FeatureRow(icon: "chart.xyaxis.line", text: "See food-symptom correlations")
                FeatureRow(icon: "checkmark.seal.fill", text: "Follow elimination protocol")
            }
            .padding(.horizontal, 40)
            Spacer()
            Button {
                currentSettings?.primaryGoal = selectedGoal.rawValue
                currentSettings?.hasCompletedOnboarding = true
            } label: {
                Text("Start Tracking")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(NourishTheme.sage, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 48)
        }
    }
}

private struct GoalRow: View {
    let goal: PrimaryGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: goal.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : NourishTheme.sage)
                    .frame(width: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.displayName)
                        .font(.headline)
                    Text(goal.description)
                        .font(.caption)
                        .lineLimit(2)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .background(isSelected ? NourishTheme.sage : NourishTheme.card, in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(isSelected ? .white : NourishTheme.charcoal)
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(NourishTheme.sage)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}

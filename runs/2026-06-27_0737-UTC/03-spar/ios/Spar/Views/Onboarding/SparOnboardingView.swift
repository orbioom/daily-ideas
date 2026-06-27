import SwiftUI
import SwiftData

struct SparOnboardingView: View {
    @Bindable var settings: SparSettings
    @Environment(\.modelContext) private var context
    @State private var page = 0

    var body: some View {
        ZStack {
            SparTheme.gradient().ignoresSafeArea()
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
            Image(systemName: "figure.boxing")
                .font(.system(size: 80))
                .foregroundStyle(.white)
            Text("Spar")
                .font(.system(size: 56, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("Train smarter.\nFight better.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.85))
            Text("Your boxing & striking training companion.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(40)
    }

    private var page1: some View {
        VStack(spacing: 28) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 60))
                .foregroundStyle(.white)
            Text("Your Setup")
                .font(.title.bold())
                .foregroundStyle(.white)
            VStack(spacing: 14) {
                HStack {
                    Text("Discipline").foregroundStyle(.white)
                    Spacer()
                    Picker("", selection: $settings.defaultDiscipline) {
                        ForEach(Discipline.allCases, id: \.self) { d in
                            Text(d.rawValue).tag(d)
                        }
                    }
                    .pickerStyle(.menu).tint(.white)
                }
                Divider().background(.white.opacity(0.3))
                HStack {
                    Text("Default round").foregroundStyle(.white)
                    Spacer()
                    Picker("", selection: $settings.defaultRoundDurationSeconds) {
                        Text("2 min").tag(120)
                        Text("3 min").tag(180)
                        Text("5 min").tag(300)
                    }
                    .pickerStyle(.menu).tint(.white)
                }
                Divider().background(.white.opacity(0.3))
                HStack {
                    Text("Weekly goal").foregroundStyle(.white)
                    Spacer()
                    Picker("", selection: $settings.weeklyTrainingGoalMinutes) {
                        Text("2 hrs").tag(120)
                        Text("3 hrs").tag(180)
                        Text("5 hrs").tag(300)
                        Text("8 hrs").tag(480)
                    }
                    .pickerStyle(.menu).tint(.white)
                }
            }
            .padding(20)
            .background(.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(40)
    }

    private var page2: some View {
        VStack(spacing: 32) {
            Image(systemName: "hands.clap.fill")
                .font(.system(size: 70))
                .foregroundStyle(.white)
            Text("Let's train!")
                .font(.title.bold())
                .foregroundStyle(.white)
            Text("Log sessions, study techniques, track your fight record, and see your progress grow.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal)
            Button {
                settings.hasCompletedOnboarding = true
                try? context.save()
            } label: {
                Text("Start Training")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white)
                    .foregroundStyle(Color("SparRed"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 40)
        }
        .padding(40)
    }
}

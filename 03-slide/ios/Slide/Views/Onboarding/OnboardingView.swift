import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var ctx
    @State private var page = 0

    var body: some View {
        ZStack {
            SlideTheme.background.ignoresSafeArea()
            TabView(selection: $page) {
                OnboardPage1().tag(0)
                OnboardPage2().tag(1)
                OnboardPage3(finish: finishOnboarding).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }

    private func finishOnboarding() {
        let ob = SlideOnboarding(); ob.completed = true
        ctx.insert(ob)
        try? ctx.save()
    }
}

struct OnboardPage1: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 72))
                .foregroundStyle(SlideTheme.accent)
            Text("Slide")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("The classic 15-puzzle,\nbeautifully redesigned.")
                .multilineTextAlignment(.center)
                .foregroundStyle(SlideTheme.textSecondary)
                .font(.title3)
            Spacer()
        }
        .padding()
        .background(SlideTheme.background)
    }
}

struct OnboardPage2: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "arrow.left.and.right")
                .font(.system(size: 64))
                .foregroundStyle(SlideTheme.accent)
            Text("Arrange the Tiles")
                .font(.title.bold())
                .foregroundStyle(.white)
            Text("Tap tiles adjacent to the blank space to slide them.\nGet them in order — 1 to 15.")
                .multilineTextAlignment(.center)
                .foregroundStyle(SlideTheme.textSecondary)
            Spacer()
        }
        .padding()
        .background(SlideTheme.background)
    }
}

struct OnboardPage3: View {
    let finish: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(SlideTheme.solved)
            Text("Ready to Play?")
                .font(.title.bold())
                .foregroundStyle(.white)
            Text("5 beautiful themes. Daily challenges. Track your best.")
                .multilineTextAlignment(.center)
                .foregroundStyle(SlideTheme.textSecondary)
            Button("Let's Go") { finish() }
                .buttonStyle(.borderedProminent)
                .tint(SlideTheme.accent)
                .font(.headline)
            Spacer()
        }
        .padding()
        .background(SlideTheme.background)
    }
}

import SwiftUI
import MapKit

struct PaceOnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0
    @Environment(RunEngine.self) private var runEngine

    var body: some View {
        ZStack {
            Color("PaceDark")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    OnboardingPage1()
                        .tag(0)
                    OnboardingPage2()
                        .tag(1)
                    OnboardingPage3(onComplete: onComplete)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct OnboardingPage1: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color("PaceGreen").opacity(0.2))
                    .frame(width: 200, height: 200)
                Image(systemName: "figure.run")
                    .font(.system(size: 80))
                    .foregroundStyle(Color("AccentColor"))
            }

            VStack(spacing: 16) {
                Text("Track Every Run")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("See your route on a live map as you run. Pace, distance, elevation — all tracked in real time with GPS precision.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 32)
            }
            Spacer()
            Spacer()
        }
    }
}

private struct OnboardingPage2: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color("PaceGreen").opacity(0.2))
                    .frame(width: 200, height: 200)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color("AccentColor"))
            }

            VStack(spacing: 16) {
                Text("Your Data Stays Private")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 12) {
                    PrivacyRow(icon: "iphone", text: "All data stored on your device only")
                    PrivacyRow(icon: "person.slash", text: "No account required, ever")
                    PrivacyRow(icon: "xmark.icloud", text: "No cloud uploads, no data harvesting")
                    PrivacyRow(icon: "house.slash", text: "We never log your home address")
                }
                .padding(.horizontal, 40)
            }
            Spacer()
            Spacer()
        }
    }
}

private struct PrivacyRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color("AccentColor"))
                .frame(width: 28)
            Text(text)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}

private struct OnboardingPage3: View {
    let onComplete: () -> Void
    @Environment(RunEngine.self) private var runEngine
    @State private var permissionRequested = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color("PaceGreen").opacity(0.2))
                    .frame(width: 200, height: 200)
                Image(systemName: "location.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color("AccentColor"))
            }

            VStack(spacing: 16) {
                Text("Ready to Run?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("Pace needs your location to track your route and measure distance accurately.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 16) {
                Button(action: {
                    permissionRequested = true
                    runEngine.requestPermission()
                }) {
                    Label("Allow Location Access", systemImage: "location.fill")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color("AccentColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)

                Button(action: onComplete) {
                    Text("Maybe Later")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Spacer()
        }
        .onChange(of: runEngine.state) { _, newState in
            if newState == .ready && permissionRequested {
                onComplete()
            }
        }
    }
}

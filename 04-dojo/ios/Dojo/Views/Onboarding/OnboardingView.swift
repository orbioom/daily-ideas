import SwiftUI

struct OnboardingView: View {
    @AppStorage("dojoOnboarded") private var onboarded = false
    @AppStorage("dojoUserName") private var userName = ""
    @AppStorage("dojoCurrentBelt") private var currentBeltRaw = BjjBelt.white.rawValue

    @State private var page = 0
    @State private var nameInput = ""
    @State private var selectedBelt: BjjBelt = .white

    var body: some View {
        ZStack {
            DojoTheme.darkBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $page) {
                    OnboardingPage(
                        icon: "figure.martial.arts",
                        iconColor: DojoTheme.crimson,
                        title: "Track Your Training",
                        subtitle: "Log every session — Gi, No-Gi, wrestling, and more. See your hours, rounds, and submission ratio grow.",
                        tag: 0
                    )
                    .tag(0)

                    OnboardingPage(
                        icon: "book.fill",
                        iconColor: DojoTheme.gold,
                        title: "Build Your Library",
                        subtitle: "30 techniques pre-loaded across submissions, sweeps, takedowns, and more. Drill them, track reps, add your own notes.",
                        tag: 1
                    )
                    .tag(1)

                    OnboardingSetupPage(
                        nameInput: $nameInput,
                        selectedBelt: $selectedBelt
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: page)

                // Page indicators + navigation
                VStack(spacing: 20) {
                    HStack(spacing: 8) {
                        ForEach(0..<3) { i in
                            Circle()
                                .fill(i == page ? DojoTheme.crimson : DojoTheme.subtleText)
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut, value: page)
                        }
                    }

                    if page < 2 {
                        Button("Continue") {
                            withAnimation { page += 1 }
                        }
                        .buttonStyle(CrimsonButtonStyle())
                        .padding(.horizontal, 32)
                    } else {
                        Button("Start Training") {
                            userName = nameInput.isEmpty ? "Athlete" : nameInput
                            currentBeltRaw = selectedBelt.rawValue
                            onboarded = true
                        }
                        .buttonStyle(CrimsonButtonStyle())
                        .padding(.horizontal, 32)
                        .disabled(false)
                    }
                }
                .padding(.bottom, 48)
                .padding(.top, 24)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct OnboardingPage: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let tag: Int

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: icon)
                    .font(.system(size: 52, weight: .bold))
                    .foregroundColor(iconColor)
            }

            VStack(spacing: 16) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.body)
                    .foregroundColor(DojoTheme.subtleText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }
}

struct OnboardingSetupPage: View {
    @Binding var nameInput: String
    @Binding var selectedBelt: BjjBelt

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(DojoTheme.crimson.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: "medal.fill")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundColor(DojoTheme.gold)
            }

            VStack(spacing: 8) {
                Text("Chase Your Belt")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Tell us a bit about yourself to get started.")
                    .font(.body)
                    .foregroundColor(DojoTheme.subtleText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 16) {
                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Name")
                        .font(.caption)
                        .foregroundColor(DojoTheme.subtleText)
                    TextField("e.g. Marcus", text: $nameInput)
                        .padding(12)
                        .background(DojoTheme.cardBg)
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .tint(DojoTheme.crimson)
                }

                // Belt picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Belt")
                        .font(.caption)
                        .foregroundColor(DojoTheme.subtleText)

                    HStack(spacing: 10) {
                        ForEach(BjjBelt.allCases, id: \.self) { belt in
                            Button {
                                selectedBelt = belt
                            } label: {
                                VStack(spacing: 6) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(DojoTheme.beltColor(belt))
                                        .frame(height: 8)
                                    Text(belt.rawValue)
                                        .font(.caption2)
                                        .foregroundColor(selectedBelt == belt ? .white : DojoTheme.subtleText)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 6)
                                .background(
                                    selectedBelt == belt
                                        ? DojoTheme.beltColor(belt).opacity(0.2)
                                        : DojoTheme.cardBg
                                )
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            selectedBelt == belt ? DojoTheme.beltColor(belt) : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}

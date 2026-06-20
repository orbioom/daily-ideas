import SwiftUI
import SwiftData

struct FableOnboardingView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsQ: [FableSettings]
    @State private var step = 0
    @State private var childName = ""
    @State private var ageGroup: AgeGroup = .preschool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.129, green: 0.141, blue: 0.310), Color(red: 0.06, green: 0.04, blue: 0.18)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(i == step ? FableTheme.gold : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.spring(), value: step)
                    }
                }
                .padding(.top, 60)
                .accessibilityLabel("Step \(step+1) of 3")

                Spacer()

                Group {
                    switch step {
                    case 0: welcomeStep
                    case 1: childNameStep
                    default: ageStep
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.4), value: step)

                Spacer()

                Button(action: advance) {
                    Text(buttonTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 14).fill(FableTheme.accent))
                }
                .disabled(step == 1 && childName.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
                .accessibilityLabel(buttonTitle)
            }
        }
    }

    private var buttonTitle: String {
        switch step {
        case 0: return "Let's Create Stories"
        case 1: return "Next"
        default: return "Start Reading"
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Text("📖").font(.system(size: 80)).accessibilityHidden(true)
            Text("Welcome to Fable")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            Text("Create magical bedtime stories with your favourite characters. No internet needed — just imagination.")
                .font(.body)
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    private var childNameStep: some View {
        VStack(spacing: 20) {
            Text("⭐️").font(.system(size: 80)).accessibilityHidden(true)
            Text("Who's the story for?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            TextField("Child's name", text: $childName)
                .font(.title3)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.15)))
                .padding(.horizontal, 32)
                .accessibilityLabel("Child's name")
        }
    }

    private var ageStep: some View {
        VStack(spacing: 20) {
            Text("🌙").font(.system(size: 80)).accessibilityHidden(true)
            Text("How old is \(childName.isEmpty ? "your child" : childName)?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            VStack(spacing: 10) {
                ForEach(AgeGroup.allCases, id: \.self) { ag in
                    Button(action: { ageGroup = ag }) {
                        Text(ag.rawValue)
                            .font(.headline)
                            .foregroundColor(ageGroup == ag ? FableTheme.night : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(ageGroup == ag ? FableTheme.gold : Color.white.opacity(0.15))
                            )
                    }
                    .accessibilityLabel(ag.rawValue + (ageGroup == ag ? ", selected" : ""))
                }
            }
            .padding(.horizontal, 32)
        }
    }

    private func advance() {
        if step < 2 { step += 1 } else { complete() }
    }

    private func complete() {
        let s = settingsQ.first ?? { let ns = FableSettings(); context.insert(ns); return ns }()
        s.childName = childName.trimmingCharacters(in: .whitespaces)
        s.preferredAgeGroup = ageGroup
        s.onboardingComplete = true
        try? context.save()
    }
}

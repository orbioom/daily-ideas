import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsQuery: [KinSettings]

    @State private var step = 0
    @State private var familyName = ""
    @State private var firstName = ""
    @State private var lastName = ""

    private var settings: KinSettings? { settingsQuery.first }

    var body: some View {
        NavigationStack {
            ZStack {
                KinTheme.cream.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress dots
                    HStack(spacing: 8) {
                        ForEach(0..<3) { i in
                            Circle()
                                .fill(i == step ? KinTheme.accent : KinTheme.sepia)
                                .frame(width: i == step ? 10 : 6, height: i == step ? 10 : 6)
                                .animation(.spring(), value: step)
                        }
                    }
                    .padding(.top, 60)
                    .accessibilityLabel("Step \(step + 1) of 3")

                    Spacer()

                    Group {
                        switch step {
                        case 0: welcomeStep
                        case 1: familyNameStep
                        default: firstPersonStep
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .animation(.spring(response: 0.4), value: step)

                    Spacer()

                    Button(action: advance) {
                        Text(step == 2 ? "Begin Your Tree" : "Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(canAdvance ? KinTheme.accent : KinTheme.sepia)
                            )
                    }
                    .disabled(!canAdvance)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                    .accessibilityLabel(step == 2 ? "Begin Your Tree" : "Continue to next step")
                }
            }
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "tree.fill")
                .font(.system(size: 80))
                .foregroundColor(KinTheme.accent)
                .accessibilityHidden(true)
            Text("Welcome to Kin")
                .font(Font.kinTitle)
                .foregroundColor(KinTheme.label)
            Text("Build your private family tree.\nEvery branch, every story — yours alone.")
                .font(Font.kinBody)
                .foregroundColor(KinTheme.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.horizontal, 24)
    }

    private var familyNameStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "house.fill")
                .font(.system(size: 48))
                .foregroundColor(KinTheme.gold)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityHidden(true)
            Text("Name your family")
                .font(Font.kinTitle)
                .foregroundColor(KinTheme.label)
                .frame(maxWidth: .infinity, alignment: .center)
            Text("This appears as your tree's title.")
                .font(Font.kinBody)
                .foregroundColor(KinTheme.secondaryLabel)
                .frame(maxWidth: .infinity, alignment: .center)
            TextField("e.g. The Johnson Family", text: $familyName)
                .font(Font.kinBody)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemBackground))
                )
                .accessibilityLabel("Family name")
        }
        .padding(.horizontal, 32)
    }

    private var firstPersonStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(KinTheme.accent)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityHidden(true)
            Text("Add yourself first")
                .font(Font.kinTitle)
                .foregroundColor(KinTheme.label)
                .frame(maxWidth: .infinity, alignment: .center)
            Text("Start with your own profile, then add relatives.")
                .font(Font.kinBody)
                .foregroundColor(KinTheme.secondaryLabel)
                .frame(maxWidth: .infinity, alignment: .center)

            VStack(spacing: 12) {
                TextField("First name", text: $firstName)
                    .font(Font.kinBody)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(uiColor: .secondarySystemBackground)))
                    .accessibilityLabel("First name")
                TextField("Last name", text: $lastName)
                    .font(Font.kinBody)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(uiColor: .secondarySystemBackground)))
                    .accessibilityLabel("Last name")
            }
        }
        .padding(.horizontal, 32)
    }

    private var canAdvance: Bool {
        switch step {
        case 0: return true
        case 1: return !familyName.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return !firstName.trimmingCharacters(in: .whitespaces).isEmpty
        default: return false
        }
    }

    private func advance() {
        if step < 2 {
            step += 1
        } else {
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        let s = settings ?? {
            let ns = KinSettings()
            context.insert(ns)
            return ns
        }()
        s.familyName = familyName.trimmingCharacters(in: .whitespaces)
        let person = Person(firstName: firstName.trimmingCharacters(in: .whitespaces),
                            lastName: lastName.trimmingCharacters(in: .whitespaces))
        context.insert(person)
        s.onboardingComplete = true
        try? context.save()
    }
}

import SwiftUI
import SwiftData

struct ScaffoldOnboardingView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsQ: [ScaffoldSettings]

    @State private var step = 0
    @State private var propertyName = ""
    @State private var address = ""

    var body: some View {
        ZStack {
            ScaffoldTheme.slate.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Capsule()
                            .fill(i <= step ? ScaffoldTheme.accent : Color.white.opacity(0.2))
                            .frame(width: i == step ? 28 : 8, height: 6)
                            .animation(.spring(), value: step)
                    }
                }
                .padding(.top, 60)
                .accessibilityLabel("Step \(step+1) of 3")

                Spacer()

                Group {
                    switch step {
                    case 0: welcomeStep
                    case 1: propertyStep
                    default: readyStep
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                .animation(.spring(response: 0.4), value: step)

                Spacer()

                Button(action: advance) {
                    Text(step == 2 ? "Let's Build" : "Next")
                        .font(.headline)
                        .foregroundColor(ScaffoldTheme.slate)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(canAdvance ? ScaffoldTheme.accent : Color.white.opacity(0.3)))
                }
                .disabled(!canAdvance)
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
                .accessibilityLabel(step == 2 ? "Let's Build" : "Next step")
            }
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "hammer.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(ScaffoldTheme.accent)
                .accessibilityHidden(true)
            Text("Welcome to Scaffold")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            Text("Track every home renovation project.\nBudgets, tasks, materials — all in one place.")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    private var propertyStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "house.fill")
                .font(.system(size: 48))
                .foregroundColor(ScaffoldTheme.accent)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityHidden(true)
            Text("Your Property")
                .font(.title.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)

            TextField("Property name (e.g. Home, The Fixer-Upper)", text: $propertyName)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.12)))
                .foregroundColor(.white)
                .accentColor(ScaffoldTheme.accent)
                .accessibilityLabel("Property name")

            TextField("Address (optional)", text: $address)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.12)))
                .foregroundColor(.white)
                .accentColor(ScaffoldTheme.accent)
                .accessibilityLabel("Address")
        }
        .padding(.horizontal, 32)
    }

    private var readyStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(ScaffoldTheme.accent)
                .accessibilityHidden(true)
            Text("You're Ready!")
                .font(.title.bold())
                .foregroundColor(.white)
            Text("Add rooms to your property, then create projects for each one. Let's get to work.")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    private var canAdvance: Bool {
        switch step {
        case 0: return true
        case 1: return !propertyName.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return true
        default: return false
        }
    }

    private func advance() {
        if step < 2 { step += 1 } else { complete() }
    }

    private func complete() {
        let settings = settingsQ.first ?? {
            let s = ScaffoldSettings(); context.insert(s); return s
        }()
        let property = Property(name: propertyName.trimmingCharacters(in: .whitespaces))
        property.address = address
        context.insert(property)
        settings.onboardingComplete = true
        try? context.save()
    }
}

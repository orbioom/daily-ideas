import SwiftUI

/// Gentle first-run intro: a warm welcome, an optional emergency contact, and a
/// calm disclaimer. Gated by @AppStorage("hasOnboarded").
struct OnboardingView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage(PrefKey.hasOnboarded) private var hasOnboarded = false
    @AppStorage(PrefKey.emergencyContactName) private var contactName = ""
    @AppStorage(PrefKey.emergencyContactPhone) private var contactPhone = ""

    @State private var page = 0
    private let lastPage = 2

    var body: some View {
        ZStack {
            HavenBackground()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    welcome.tag(0)
                    contact.tag(1)
                    disclaimer.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                controls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
    }

    // MARK: Pages

    private var welcome: some View {
        VStack(spacing: 22) {
            Spacer()
            BreathingMark(reduceMotion: reduceMotion)
            Text("Welcome to Haven")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(HavenTheme.primaryText(scheme))
            Text("A calm, private place for the hard moments. When anxiety or panic rises, Haven is here to help you breathe, ground, and feel safe again.")
                .font(.body)
                .foregroundStyle(HavenTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private var contact: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: "heart.circle")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(HavenTheme.accent)
                    .padding(.top, 40)
                    .accessibilityHidden(true)
                Text("Your safe person")
                    .font(.title.weight(.bold))
                    .foregroundStyle(HavenTheme.primaryText(scheme))
                Text("If you'd like, add someone you can reach in a hard moment. This stays only on your device, and you can change it anytime. You can also skip this.")
                    .font(.subheadline)
                    .foregroundStyle(HavenTheme.secondaryText(scheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                HavenCard {
                    VStack(spacing: 12) {
                        labeledField("Their name", text: $contactName, keyboard: .default)
                        Divider()
                        labeledField("Their phone", text: $contactPhone, keyboard: .phonePad)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 20)
        }
    }

    private var disclaimer: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: "hand.raised.circle")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(HavenTheme.accent)
                    .padding(.top, 40)
                    .accessibilityHidden(true)
                Text("A gentle note")
                    .font(.title.weight(.bold))
                    .foregroundStyle(HavenTheme.primaryText(scheme))

                HavenCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Haven is a self-help companion — not a medical device, and not a substitute for professional care or crisis services.")
                            .foregroundStyle(HavenTheme.primaryText(scheme))
                        Text("If you're in crisis or thinking about harming yourself, please reach out for real-time help. In the US, you can call or text 988 anytime. In an emergency, call your local emergency number.")
                            .foregroundStyle(HavenTheme.secondaryText(scheme))
                        Text("You deserve support. Haven is here for the in-between moments.")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(HavenTheme.accentDeep)
                    }
                    .font(.subheadline)
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 20)
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: Controls

    private var controls: some View {
        VStack(spacing: 14) {
            PageDots(count: lastPage + 1, current: page)
            Button {
                advance()
            } label: {
                Text(page == lastPage ? "I'm ready" : "Continue")
            }
            .havenPillButton()
            .accessibilityHint(page == lastPage ? "Finishes setup and opens Haven" : "Goes to the next step")

            if page == 1 {
                Button("Skip for now") { withTransition { page = 2 } }
                    .font(.subheadline)
                    .foregroundStyle(HavenTheme.secondaryText(scheme))
            }
        }
    }

    private func advance() {
        if page < lastPage {
            withTransition { page += 1 }
        } else {
            hasOnboarded = true
        }
    }

    private func withTransition(_ change: () -> Void) {
        if reduceMotion {
            change()
        } else {
            withAnimation(.easeInOut) { change() }
        }
    }

    private func labeledField(_ label: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(HavenTheme.secondaryText(scheme))
            TextField(label, text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .phonePad ? .never : .words)
                .foregroundStyle(HavenTheme.primaryText(scheme))
                .accessibilityLabel(label)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Decorative breathing mark (degrades under Reduce Motion)

struct BreathingMark: View {
    let reduceMotion: Bool
    @State private var expanded = false

    var body: some View {
        ZStack {
            Circle()
                .fill(HavenTheme.orbGradient)
                .frame(width: 150, height: 150)
                .scaleEffect(reduceMotion ? 1.0 : (expanded ? 1.08 : 0.92))
                .opacity(0.9)
            Image(systemName: "wind")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.white)
        }
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                expanded = true
            }
        }
    }
}

// MARK: - Page dots

struct PageDots: View {
    let count: Int
    let current: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .fill(i == current ? HavenTheme.accent : HavenTheme.accent.opacity(0.25))
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityHidden(true)
    }
}

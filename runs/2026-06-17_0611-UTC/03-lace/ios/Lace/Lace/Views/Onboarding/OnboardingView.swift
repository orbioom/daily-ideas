import SwiftUI
import SwiftData

/// First-run onboarding: a short motivational intro plus a pick-a-plan step
/// that enrolls the user. Gated by the persisted `hasOnboarded` flag.
struct OnboardingView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Environment(ProStore.self) private var pro
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false

    @State private var page = 0
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Theme.appBackground(scheme).ignoresSafeArea()
            TabView(selection: $page) {
                intro.tag(0)
                planPicker.tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    // MARK: - Intro

    private var intro: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle().fill(Theme.coral.opacity(0.16)).frame(width: 132, height: 132)
                Image(systemName: "figure.run")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(Theme.coral)
            }
            .accessibilityHidden(true)
            VStack(spacing: 12) {
                Text("Lace up.")
                    .font(Theme.display(40))
                    .foregroundStyle(Theme.primaryText(scheme))
                Text("Go from the couch to running 5K in nine weeks — guided, ad-free, and completely free.")
                    .font(.title3)
                    .foregroundStyle(Theme.secondaryText(scheme))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 28)

            VStack(alignment: .leading, spacing: 14) {
                feature("waveform", "A real coach in your ear", "Spoken run/walk cues, countdowns and haptics.")
                feature("bolt.heart.fill", "The whole plan, free", "All nine weeks. No paywall after day three.")
                feature("chart.bar.fill", "See yourself improve", "Streaks, minutes and a graduation to 5K.")
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Theme.cardSurface(scheme))
            )
            .padding(.horizontal, 24)

            Spacer()
            Button("Choose your plan") { withAnimation { page = 1 } }
                .buttonStyle(LacePrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
        }
    }

    private func feature(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.coral)
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.primaryText(scheme))
                Text(detail).font(.caption)
                    .foregroundStyle(Theme.secondaryText(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Plan picker

    private var planPicker: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("Pick where to begin")
                        .font(Theme.display(28))
                        .foregroundStyle(Theme.primaryText(scheme))
                    Text("New to running? Couch to 5K is the classic. You can switch any time.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText(scheme))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 28)
                .padding(.horizontal, 24)

                ForEach(BuiltInPlans.all) { plan in
                    Button {
                        choose(plan)
                    } label: {
                        LaceCard {
                            PlanCardRow(plan: plan, locked: plan.isPro && !pro.isPro)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                }

                Text("Couch to 5K and the guided player are free forever. Easy Start and the 10K bridge are part of Lace Pro.")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText(scheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 24)
            }
        }
    }

    private func choose(_ plan: TrainingPlan) {
        if plan.isPro && !pro.isPro {
            showPaywall = true
            return
        }
        Enrollment.enroll(in: plan, context: modelContext)
        Haptics.success(settings.hapticCues)
        hasOnboarded = true
    }
}

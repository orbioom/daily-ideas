import SwiftUI
import SwiftData

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("activePlanID") private var activePlanID = "c25k"
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var selectedPlan = "c25k"

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack {
                TabView(selection: $page) {
                    intro(symbol: "figure.run",
                          title: "Become a runner",
                          body: "Lope is a guided run-walk coach. Three short sessions a week and it tells you exactly when to run and when to walk.")
                        .tag(0)
                    intro(symbol: "speaker.wave.2",
                          title: "A voice in your ear",
                          body: "No staring at your phone. Lope speaks every cue and taps your wrist at each switch, so you just run.")
                        .tag(1)
                    planPicker.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button {
                    if page < 2 { withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 } }
                    else { start() }
                } label: {
                    Text(page < 2 ? "Continue" : "Start training")
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.accent))
                        .foregroundStyle(Theme.accentInk)
                }
                .padding(.horizontal, 24).padding(.bottom, 20)
            }
        }
    }

    private func intro(symbol: String, title: String, body: String) -> some View {
        VStack(spacing: 26) {
            Spacer()
            ZStack {
                Circle().fill(Theme.accent.opacity(0.18)).frame(width: 150, height: 150)
                Image(systemName: symbol).font(.system(size: 62, weight: .medium))
                    .foregroundStyle(Theme.accent).accessibilityHidden(true)
            }
            Text(title).font(Theme.display(30)).foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(body).font(.system(size: 17)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center).padding(.horizontal, 36)
            Spacer(); Spacer()
        }
    }

    private var planPicker: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("Pick your starting plan")
                .font(Theme.display(26)).foregroundStyle(Theme.ink)
            Text("You can switch any time.")
                .font(.system(size: 15)).foregroundStyle(Theme.inkSoft)
            ForEach(PlanLibrary.all) { plan in
                Button { selectedPlan = plan.id; Haptics.tap() } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(plan.name).font(Theme.display(20)).foregroundStyle(Theme.ink)
                            Spacer()
                            Image(systemName: selectedPlan == plan.id ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedPlan == plan.id ? Theme.accent : Theme.inkFaint)
                                .font(.system(size: 22))
                        }
                        Text(plan.subtitle).font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                        Text(plan.blurb).font(.system(size: 14)).foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 18)
                        .fill(Theme.surface)
                        .overlay(RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(selectedPlan == plan.id ? Theme.accent : .clear, lineWidth: 2)))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private func start() {
        activePlanID = selectedPlan
        let existing = (try? context.fetchCount(FetchDescriptor<RunLog>())) ?? 0
        if existing == 0 { SeedData.seedStarter(context, planID: selectedPlan) }
        Haptics.success()
        hasOnboarded = true
    }
}

import SwiftUI
import SwiftData

/// Plan chooser used from the Home empty state and the "switch plan" flow.
/// Lists built-in plans and any custom plans; enrolling replaces the current
/// enrollment.
struct ChoosePlanView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings
    @Environment(ProStore.self) private var pro

    @Query private var activePlans: [ActivePlan]
    @Query(sort: \CustomPlan.createdAt, order: .reverse) private var customPlans: [CustomPlan]

    @State private var showPaywall = false
    @State private var pendingSwitch: TrainingPlan?

    private var activeId: String? { activePlans.first?.planId }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                LaceSectionHeader(title: "Built-in plans", systemImage: "star.fill")
                    .padding(.horizontal, 4)

                ForEach(BuiltInPlans.all) { plan in
                    planButton(plan)
                }

                if !customPlans.isEmpty {
                    LaceSectionHeader(title: "Your custom plans", systemImage: "slider.horizontal.3")
                        .padding(.horizontal, 4)
                        .padding(.top, 6)
                    ForEach(customPlans) { cp in
                        planButton(cp.asTrainingPlan())
                    }
                }

                Text("Switching plans keeps your completed history but restarts your week-by-week position.")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText(scheme))
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
            }
            .padding(20)
        }
        .laceScreenBackground(scheme)
        .navigationTitle("Choose a plan")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .alert("Switch to \(pendingSwitch?.title ?? "this plan")?",
               isPresented: Binding(get: { pendingSwitch != nil }, set: { if !$0 { pendingSwitch = nil } })) {
            Button("Cancel", role: .cancel) { pendingSwitch = nil }
            Button("Switch") {
                if let p = pendingSwitch { enroll(p) }
                pendingSwitch = nil
            }
        } message: {
            Text("Your current week position will reset to Week 1. Completed sessions are kept.")
        }
    }

    private func planButton(_ plan: TrainingPlan) -> some View {
        let locked = plan.isPro && !pro.isPro
        return Button {
            tap(plan, locked: locked)
        } label: {
            LaceCard {
                PlanCardRow(plan: plan, locked: locked, isActive: plan.id == activeId)
            }
        }
        .buttonStyle(.plain)
    }

    private func tap(_ plan: TrainingPlan, locked: Bool) {
        if locked { showPaywall = true; return }
        if activeId == nil {
            enroll(plan)
        } else if plan.id != activeId {
            pendingSwitch = plan
        } else {
            dismiss()   // already active
        }
    }

    private func enroll(_ plan: TrainingPlan) {
        Enrollment.enroll(in: plan, context: modelContext)
        Haptics.success(settings.hapticCues)
        dismiss()
    }
}

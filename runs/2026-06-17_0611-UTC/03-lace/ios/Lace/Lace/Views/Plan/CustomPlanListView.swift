import SwiftUI
import SwiftData

/// Lists the user's custom plans and offers a builder (Pro feature).
struct CustomPlanListView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings

    @Query(sort: \CustomPlan.createdAt, order: .reverse) private var plans: [CustomPlan]

    @State private var editingPlan: CustomPlan?

    var body: some View {
        Group {
            if plans.isEmpty {
                ScrollView {
                    EmptyStateView(
                        icon: "slider.horizontal.3",
                        title: "Build your own",
                        message: "Design a plan from scratch — add sessions and run/walk intervals exactly how you want them.",
                        actionTitle: "New plan",
                        action: createPlan
                    )
                    .padding(.top, 50)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(plans) { plan in
                            Button {
                                editingPlan = plan
                            } label: {
                                LaceCard {
                                    HStack(spacing: 14) {
                                        Image(systemName: "slider.horizontal.3")
                                            .font(.title3.weight(.bold))
                                            .foregroundStyle(Theme.coral)
                                            .accessibilityHidden(true)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(plan.title.isEmpty ? "Untitled plan" : plan.title)
                                                .font(.headline)
                                                .foregroundStyle(Theme.primaryText(scheme))
                                            Text("\(plan.sessions.count) session\(plan.sessions.count == 1 ? "" : "s")")
                                                .font(.subheadline)
                                                .foregroundStyle(Theme.secondaryText(scheme))
                                        }
                                        Spacer(minLength: 0)
                                        Image(systemName: "chevron.right")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Theme.secondaryText(scheme))
                                            .accessibilityHidden(true)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .laceScreenBackground(scheme)
        .navigationTitle("Custom plans")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { createPlan() } label: { Image(systemName: "plus") }
                    .accessibilityLabel("New custom plan")
            }
        }
        .sheet(item: $editingPlan) { plan in
            CustomPlanEditorView(plan: plan)
        }
    }

    private func createPlan() {
        let plan = CustomPlan(title: "My plan")
        // Seed with one starter session so the editor isn't empty.
        let session = CustomSession(title: "Session 1", order: 0, plan: plan)
        session.intervals = [
            CustomInterval(kind: .warmup, durationSeconds: 300, order: 0, session: session),
            CustomInterval(kind: .run, durationSeconds: 60, order: 1, session: session),
            CustomInterval(kind: .walk, durationSeconds: 90, order: 2, session: session),
            CustomInterval(kind: .cooldown, durationSeconds: 300, order: 3, session: session)
        ]
        plan.sessions = [session]
        modelContext.insert(plan)
        try? modelContext.save()
        Haptics.tap(settings.hapticCues)
        editingPlan = plan
    }
}

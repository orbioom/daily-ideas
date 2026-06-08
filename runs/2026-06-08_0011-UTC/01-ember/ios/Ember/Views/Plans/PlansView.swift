import SwiftUI
import SwiftData

struct PlansView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Plan.order) private var plans: [Plan]

    @AppStorage("ember.activePlanName") private var planName = "16:8"
    @AppStorage("ember.activeGoalHours") private var goalHours = 16.0

    @State private var editing: Plan?
    @State private var showingNew = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if plans.isEmpty {
                    EmptyStateView(icon: "target", title: "No plans",
                                   message: "Add a fasting protocol to get started.")
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(plans) { plan in
                                planCard(plan)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Plans")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNew = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add custom plan")
                }
            }
            .sheet(isPresented: $showingNew) {
                PlanEditView(plan: nil)
            }
            .sheet(item: $editing) { plan in
                PlanEditView(plan: plan)
            }
        }
    }

    private func planCard(_ plan: Plan) -> some View {
        let selected = plan.name == planName
        return Button {
            planName = plan.name
            goalHours = plan.fastHours
            Haptics.selection()
        } label: {
            GlassCard {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(plan.name)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(Brand.text)
                            if plan.isCustom {
                                Text("CUSTOM")
                                    .font(Brand.mono(9, weight: .medium))
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Brand.hairline, in: Capsule())
                                    .foregroundStyle(Brand.text2)
                            }
                        }
                        Text(plan.detail)
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                        Text("Fast \(Int(plan.fastHours))h · eat \(Int(plan.eatHours))h")
                            .font(Brand.mono(12))
                            .foregroundStyle(Brand.text3)
                    }
                    Spacer()
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(selected ? Brand.live : Brand.text3)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(plan.name), \(plan.detail)")
        .accessibilityValue(selected ? "Selected" : "Not selected")
        .contextMenu {
            if plan.isCustom {
                Button { editing = plan } label: { Label("Edit", systemImage: "pencil") }
                Button(role: .destructive) {
                    if plan.name == planName { planName = "16:8"; goalHours = 16 }
                    context.delete(plan); try? context.save()
                } label: { Label("Delete", systemImage: "trash") }
            }
        }
    }
}

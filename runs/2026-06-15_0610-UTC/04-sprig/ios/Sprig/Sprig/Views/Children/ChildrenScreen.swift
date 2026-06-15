import SwiftUI
import SwiftData

/// Home: the list of children with an age + percentile snapshot, next milestone, next vaccine.
struct ChildrenScreen: View {
    @AppStorage("isPro") private var isPro = false
    @AppStorage("selectedChildID") private var selectedChildID = ""

    @Query(sort: \Child.createdAt, order: .forward) private var children: [Child]

    @State private var showAddChild = false
    @State private var paywallReason: PaywallReason?

    var body: some View {
        NavigationStack {
            Group {
                if children.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Sprig")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        attemptAdd()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add child")
                }
            }
            .sheet(isPresented: $showAddChild) {
                AddChildView { child in
                    selectedChildID = child.id.uuidString
                }
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(children) { child in
                    NavigationLink {
                        ChildDetailView(child: child)
                    } label: {
                        ChildRow(summary: ChildSummary.build(for: child))
                    }
                    .buttonStyle(.plain)
                }

                disclaimer
            }
            .padding(16)
        }
    }

    private var emptyState: some View {
        ScrollView {
            EmptyStateView(symbol: "figure.2.and.child.holdinghands",
                           title: "No children yet",
                           message: "Add your first child to start plotting growth percentiles, milestones, and vaccines.",
                           actionTitle: "Add a child") {
                attemptAdd()
            }
            .padding(.top, 60)
        }
    }

    private var disclaimer: some View {
        Text("Sprig is for informational purposes only and is not medical advice. Always follow your pediatrician's guidance.")
            .font(Theme.rounded(12))
            .foregroundStyle(Theme.inkFaint)
            .multilineTextAlignment(.center)
            .padding(.top, 8)
            .padding(.horizontal, 12)
    }

    private func attemptAdd() {
        if Pro.canAddChild(currentCount: children.count, isPro: isPro) {
            showAddChild = true
        } else {
            paywallReason = .multipleChildren
        }
    }
}

/// A single child card on the Home list.
private struct ChildRow: View {
    let summary: ChildSummary

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    ChildAvatar(child: summary.child, size: 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(summary.child.displayName)
                            .font(Theme.rounded(20, .bold))
                            .foregroundStyle(Theme.ink)
                        Text("\(summary.child.sex.title) · \(summary.ageDescription)")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.inkFaint)
                        .accessibilityHidden(true)
                }

                if summary.measurementCount > 0 {
                    HStack(spacing: 8) {
                        PercentilePill(measure: .weight, result: summary.weightPercentile)
                        PercentilePill(measure: .height, result: summary.heightPercentile)
                        PercentilePill(measure: .head, result: summary.headPercentile)
                    }
                } else {
                    Text("No measurements yet — add one on the Growth tab.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }

                Divider().overlay(Theme.hairline)

                VStack(alignment: .leading, spacing: 8) {
                    if let milestone = summary.nextMilestone {
                        infoLine(symbol: milestone.category.symbol,
                                 label: "Next milestone",
                                 value: milestone.title,
                                 tint: Theme.accent)
                    }
                    if let dose = summary.nextVaccine, let status = summary.nextVaccineStatus {
                        infoLine(symbol: "cross.case.fill",
                                 label: status == .upcoming ? "Upcoming vaccine" : "Vaccine \(status.title.lowercased())",
                                 value: "\(dose.name) · \(dose.doseLabel)",
                                 tint: vaccineTint(status))
                    }
                }
            }
        }
    }

    private func infoLine(symbol: String, label: String, value: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 18)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(Theme.rounded(11, .semibold))
                    .foregroundStyle(Theme.inkFaint)
                Text(value)
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }

    private func vaccineTint(_ status: VaccineStatus) -> Color {
        switch status {
        case .overdue: return Theme.bad
        case .due:     return Theme.warn
        default:       return Theme.accent
        }
    }
}

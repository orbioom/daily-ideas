import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Kid.sortIndex) private var kids: [Kid]
    @AppStorage("sprout.symbol") private var symbol = "$"
    @AppStorage("sprout.autoApprove") private var autoApprove = false

    private var pending: [Completion] { ChoreEngine.pendingApprovals(kids) }

    var body: some View {
        NavigationStack {
            Group {
                if kids.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "person.2",
                                       title: "No kids yet",
                                       message: "Add a child in the Kids tab, then assign chores to build today's board.")
                            .glassCard().padding(20)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            if !pending.isEmpty { approvalsCard }
                            ForEach(kids) { kid in kidBoard(kid) }
                        }
                        .padding(20)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Today")
        }
    }

    private var approvalsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "hand.raised.fill").foregroundStyle(Brand.warn)
                    Eyebrow(text: "Waiting for approval")
                    Spacer()
                    Text("\(pending.count)").font(Brand.mono(13)).foregroundStyle(Brand.text3)
                }
                ForEach(pending) { comp in
                    HStack(spacing: 10) {
                        if let kid = comp.kid { KidAvatar(kid: kid, size: 28) }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(comp.choreTitle).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                            Text("\(comp.kid?.name ?? "") · \(comp.points) pts\(comp.reward > 0 ? " · \(Money.string(comp.reward, symbol: symbol))" : "")")
                                .font(.caption).foregroundStyle(Brand.text3)
                        }
                        Spacer()
                        Button {
                            Haptics.success(); comp.approved = true; try? context.save()
                        } label: { Image(systemName: "checkmark.circle.fill").font(.title2).foregroundStyle(Brand.live) }
                            .buttonStyle(.plain).accessibilityLabel("Approve \(comp.choreTitle)")
                        Button {
                            Haptics.tap(); context.delete(comp); try? context.save()
                        } label: { Image(systemName: "xmark.circle.fill").font(.title2).foregroundStyle(Brand.danger) }
                            .buttonStyle(.plain).accessibilityLabel("Reject \(comp.choreTitle)")
                    }
                    .padding(.vertical, 3)
                }
            }
        }
    }

    private func kidBoard(_ kid: Kid) -> some View {
        let items = ChoreEngine.todayItems(for: kid)
        let progress = ChoreEngine.todayProgress(for: kid)
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    KidAvatar(kid: kid, size: 40)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(kid.name).font(.headline).foregroundStyle(Brand.text)
                        Text("\(items.filter { $0.done }.count) of \(items.count) done today")
                            .font(.caption).foregroundStyle(Brand.text3)
                    }
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(Brand.mono(15, weight: .semibold))
                        .foregroundStyle(progress >= 1 ? Brand.live : kid.color.color)
                }
                if items.isEmpty {
                    Text("No chores scheduled today.").font(.subheadline).foregroundStyle(Brand.text3)
                        .padding(.vertical, 4)
                } else {
                    ForEach(items) { item in choreToggle(item, kid: kid) }
                }
            }
        }
    }

    private func choreToggle(_ item: ChoreEngine.TodayItem, kid: Kid) -> some View {
        Button {
            toggle(item, kid: kid)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.done ? Brand.live : Brand.text3)
                Image(systemName: item.chore.symbol).foregroundStyle(kid.color.color).frame(width: 24)
                    .accessibilityHidden(true)
                Text(item.chore.title)
                    .font(.subheadline)
                    .strikethrough(item.done, color: Brand.text3)
                    .foregroundStyle(item.done ? Brand.text3 : Brand.text)
                Spacer()
                HStack(spacing: 6) {
                    Text("\(item.chore.points)p").font(Brand.mono(12)).foregroundStyle(Brand.text3)
                    if item.chore.reward > 0 {
                        Text(Money.string(item.chore.reward, symbol: symbol))
                            .font(Brand.mono(12)).foregroundStyle(Brand.live)
                    }
                }
                if let comp = item.completion, !comp.approved {
                    Image(systemName: "clock.fill").font(.caption2).foregroundStyle(Brand.warn)
                        .accessibilityLabel("Pending approval")
                }
            }
            .padding(.vertical, 3)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.chore.title), \(item.done ? "done" : "not done")")
        .accessibilityHint(item.done ? "Double tap to undo" : "Double tap to mark done")
    }

    private func toggle(_ item: ChoreEngine.TodayItem, kid: Kid) {
        if let comp = item.completion {
            context.delete(comp)
            Haptics.tap()
        } else {
            let comp = Completion(date: .now, choreTitle: item.chore.title,
                                  reward: item.chore.reward, points: item.chore.points,
                                  approved: autoApprove)
            comp.kid = kid
            comp.chore = item.chore
            context.insert(comp)
            Haptics.success()
        }
        try? context.save()
    }
}

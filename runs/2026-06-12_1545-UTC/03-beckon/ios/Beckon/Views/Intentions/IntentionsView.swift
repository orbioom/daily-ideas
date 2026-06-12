import SwiftUI
import SwiftData

struct IntentionsView: View {
    @Query(sort: \Intention.createdAt, order: .reverse) private var intentions: [Intention]
    @State private var showAdd = false

    private var active: [Intention] { intentions.filter { $0.state == .active } }
    private var manifested: [Intention] { intentions.filter { $0.state == .manifested } }
    private var released: [Intention] { intentions.filter { $0.state == .released } }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()
                if intentions.isEmpty {
                    EmptyStateView(symbol: "star.circle",
                                   title: "No intentions yet",
                                   message: "Your manifestation list lives here. Add what you're calling in to begin.",
                                   actionTitle: "New intention") { showAdd = true }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            section("Active", active)
                            section("Manifested", manifested)
                            section("Released", released)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Intentions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("New intention")
                }
            }
            .navigationDestination(for: Intention.self) { IntentionDetailView(intention: $0) }
            .sheet(isPresented: $showAdd) { IntentionEditView(intention: nil) }
        }
    }

    @ViewBuilder private func section(_ title: String, _ list: [Intention]) -> some View {
        if !list.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(title).font(.headline).foregroundStyle(Theme.textPrimary)
                ForEach(list) { intent in
                    NavigationLink(value: intent) { IntentionRow(intention: intent) }
                        .buttonStyle(.plain)
                }
            }
        }
    }
}

struct IntentionRow: View {
    let intention: Intention
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(intention.tint.opacity(0.18)).frame(width: 46, height: 46)
                Image(systemName: intention.category.symbol).foregroundStyle(intention.tint)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(intention.title).font(.headline).foregroundStyle(Theme.textPrimary).lineLimit(1)
                Text(intention.affirmation).font(.caption).foregroundStyle(Theme.textSecondary).lineLimit(2)
                if intention.state == .active {
                    ProgressView(value: intention.cycleProgress).tint(intention.tint)
                        .padding(.top, 2)
                } else if intention.state == .manifested {
                    Label("Manifested", systemImage: "checkmark.seal.fill")
                        .font(.caption2.weight(.semibold)).foregroundStyle(Theme.accent)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Theme.textSecondary)
        }
        .beckonCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(intention.title), \(intention.state.rawValue)")
    }
}

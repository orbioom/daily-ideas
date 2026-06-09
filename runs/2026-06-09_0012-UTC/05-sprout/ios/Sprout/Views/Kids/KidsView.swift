import SwiftUI
import SwiftData

struct KidsView: View {
    @Query(sort: \Kid.sortIndex) private var kids: [Kid]
    @AppStorage("sprout.symbol") private var symbol = "$"
    @State private var adding = false

    var body: some View {
        NavigationStack {
            Group {
                if kids.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "person.2.fill",
                                       title: "No kids",
                                       message: "Add your children to start building chore boards and tracking allowance.")
                            .glassCard().padding(20)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(kids) { kid in
                                NavigationLink { KidDetailView(kid: kid) } label: { kidCard(kid) }
                                    .buttonStyle(.plain)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Kids")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); adding = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add child")
                }
            }
            .sheet(isPresented: $adding) { KidEditorView(kid: nil, nextIndex: kids.count) }
        }
    }

    private func kidCard(_ kid: Kid) -> some View {
        HStack(spacing: 14) {
            KidAvatar(kid: kid, size: 56)
            VStack(alignment: .leading, spacing: 3) {
                Text(kid.name).font(.headline).foregroundStyle(Brand.text)
                HStack(spacing: 12) {
                    Label("\(kid.totalPoints) pts", systemImage: "star.fill")
                        .font(.caption).foregroundStyle(Brand.warn)
                    Label(ChoreEngine.completionsThisWeek(for: kid).description + " this week",
                          systemImage: "checkmark.seal.fill")
                        .font(.caption).foregroundStyle(Brand.text3)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Money.string(kid.balance, symbol: symbol))
                    .font(Brand.mono(18, weight: .semibold))
                    .foregroundStyle(kid.balance >= 0 ? Brand.text : Brand.danger)
                Text("balance").font(.caption2).foregroundStyle(Brand.text3)
            }
            Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(Brand.text3)
                .accessibilityHidden(true)
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(kid.name), \(Money.string(kid.balance, symbol: symbol)), \(kid.totalPoints) points")
    }
}

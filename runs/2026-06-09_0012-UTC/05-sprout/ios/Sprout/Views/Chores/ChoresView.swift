import SwiftUI
import SwiftData

struct ChoresView: View {
    @Query(sort: \Kid.sortIndex) private var kids: [Kid]
    @AppStorage("sprout.symbol") private var symbol = "$"
    @State private var adding = false
    @State private var editing: Chore?

    var body: some View {
        NavigationStack {
            Group {
                if kids.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "list.bullet.rectangle.portrait",
                                       title: "Add a child first",
                                       message: "Chores are assigned to a child. Add someone in the Kids tab to begin.")
                            .glassCard().padding(20)
                    }
                } else if kids.allSatisfy({ $0.chores.isEmpty }) {
                    ScrollView {
                        VStack(spacing: 16) {
                            EmptyStateView(icon: "plus.rectangle.on.folder",
                                           title: "No chores yet",
                                           message: "Tap + to create your first chore and assign it to a child.")
                                .glassCard()
                        }
                        .padding(20)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            ForEach(kids.filter { !$0.chores.isEmpty }) { kid in
                                kidChores(kid)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Chores")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); adding = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("New chore")
                        .disabled(kids.isEmpty)
                }
            }
            .sheet(isPresented: $adding) { ChoreEditorView(chore: nil, kids: kids) }
            .sheet(item: $editing) { ChoreEditorView(chore: $0, kids: kids) }
        }
    }

    private func kidChores(_ kid: Kid) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    KidAvatar(kid: kid, size: 30)
                    Text(kid.name).font(.headline).foregroundStyle(Brand.text)
                    Spacer()
                    Text("\(kid.chores.count)").font(Brand.mono(13)).foregroundStyle(Brand.text3)
                }
                ForEach(kid.chores.sorted { $0.sortIndex < $1.sortIndex }) { chore in
                    Button { Haptics.tap(); editing = chore } label: { choreRow(chore) }
                        .buttonStyle(.plain)
                }
            }
        }
    }

    private func choreRow(_ chore: Chore) -> some View {
        HStack(spacing: 12) {
            Image(systemName: chore.symbol).foregroundStyle(chore.isActive ? Brand.text2 : Brand.text3)
                .frame(width: 26).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(chore.title).font(.subheadline.weight(.medium))
                    .foregroundStyle(chore.isActive ? Brand.text : Brand.text3)
                Text(chore.scheduleSummary).font(.caption).foregroundStyle(Brand.text3)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text("\(chore.points) pts").font(Brand.mono(12)).foregroundStyle(Brand.warn)
                if chore.reward > 0 {
                    Text(Money.string(chore.reward, symbol: symbol)).font(Brand.mono(12)).foregroundStyle(Brand.live)
                }
            }
            if !chore.isActive {
                Text("Off").font(.caption2).foregroundStyle(Brand.text3)
            }
            Image(systemName: "chevron.right").font(.caption2.weight(.bold)).foregroundStyle(Brand.text3)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

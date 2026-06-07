import SwiftUI
import SwiftData

struct TablesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ApneaTable.createdAt, order: .reverse) private var tables: [ApneaTable]
    @Query private var sessions: [ApneaSession]
    @AppStorage("static.confirmDeletes") private var confirmDeletes = true
    @State private var showNew = false
    @State private var pendingDelete: ApneaTable?

    private var personalBest: Int { sessions.map { $0.longestHoldSeconds }.max() ?? 0 }

    var body: some View {
        NavigationStack {
            Group {
                if tables.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "lungs",
                                       title: "No tables yet",
                                       message: "Create a CO₂ or O₂ table from your max breath-hold and start training.")
                            .padding(.top, 40)
                        Button { showNew = true } label: {
                            Label("New table", systemImage: "plus")
                        }.buttonStyle(InkButtonStyle()).padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            if personalBest > 0 {
                                HStack {
                                    Image(systemName: "trophy").foregroundStyle(Brand.magic)
                                        .accessibilityHidden(true)
                                    Text("Personal best").foregroundStyle(Brand.text2).font(.subheadline)
                                    Spacer()
                                    Text(TableEngine.clock(personalBest))
                                        .font(Brand.mono(18, weight: .bold)).foregroundStyle(Brand.text)
                                }.glassCard()
                            }
                            ForEach(tables) { table in
                                NavigationLink { TableDetailView(table: table) } label: {
                                    TableRow(table: table)
                                }.buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        if confirmDeletes { pendingDelete = table } else { delete(table) }
                                    } label: { Label("Delete", systemImage: "trash") }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Train")
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNew = true } label: { Image(systemName: "plus") }.tint(Brand.text)
                }
            }
            .sheet(isPresented: $showNew) { TableEditView(suggestedMax: max(120, personalBest)) }
            .confirmationDialog("Delete this table?", isPresented: Binding(
                get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let t = pendingDelete { delete(t) } }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    private func delete(_ t: ApneaTable) {
        context.delete(t); try? context.save(); Haptics.warning(); pendingDelete = nil
    }
}

private struct TableRow: View {
    let table: ApneaTable
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: table.type.symbol)
                .font(.title2).foregroundStyle(Brand.text).frame(width: 34)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(table.name).font(.headline).foregroundStyle(Brand.text)
                HStack(spacing: 8) {
                    Badge(text: "\(table.type.rawValue) table")
                    Badge(text: "\(table.rounds) rounds")
                    Badge(text: "~\(TableEngine.clock(table.totalSeconds))")
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Brand.text3)
        }
        .glassCard()
    }
}

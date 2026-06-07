import SwiftUI
import SwiftData

struct NotebookView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SavedCalc.createdAt, order: .reverse) private var calcs: [SavedCalc]
    @AppStorage("bench.confirmDeletes") private var confirmDeletes = true
    @State private var selected: SavedCalc?
    @State private var pendingDelete: SavedCalc?

    var body: some View {
        NavigationStack {
            Group {
                if calcs.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "book",
                                       title: "Notebook is empty",
                                       message: "Run a calculator and tap “Save to notebook” to keep its result here for later.")
                            .padding(.top, 50)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(calcs) { calc in
                                Button { selected = calc } label: { row(calc) }.buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            if confirmDeletes { pendingDelete = calc } else { delete(calc) }
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Notebook")
            .background(Brand.pageBackground)
            .sheet(item: $selected) { calc in detailSheet(calc) }
            .confirmationDialog("Delete this saved calculation?", isPresented: Binding(
                get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let c = pendingDelete { delete(c) } }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    private func row(_ calc: SavedCalc) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(calc.title).font(.headline).foregroundStyle(Brand.text)
                HStack(spacing: 8) {
                    Badge(text: calc.tool)
                    Text(calc.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption).foregroundStyle(Brand.text3)
                }
            }
            Spacer()
            Text(calc.summary).font(Brand.mono(13, weight: .medium)).foregroundStyle(Brand.live)
                .multilineTextAlignment(.trailing)
        }
        .glassCard()
    }

    private func detailSheet(_ calc: SavedCalc) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Badge(text: calc.tool)
                        Text(calc.title).font(.title3.weight(.semibold)).foregroundStyle(Brand.text)
                    }.frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "Result")
                        Text(calc.detail)
                            .font(Brand.mono(14)).foregroundStyle(Brand.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }.glassCard()

                    Text("Saved \(calc.createdAt.formatted(date: .complete, time: .shortened))")
                        .font(.caption).foregroundStyle(Brand.text3)
                }
                .padding()
            }
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { selected = nil }.tint(Brand.text) } }
        }
    }

    private func delete(_ c: SavedCalc) {
        context.delete(c); try? context.save(); Haptics.warning(); pendingDelete = nil
    }
}

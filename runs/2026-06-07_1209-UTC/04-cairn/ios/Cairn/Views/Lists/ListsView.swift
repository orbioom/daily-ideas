import SwiftUI
import SwiftData

struct ListsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PackList.createdAt, order: .reverse) private var lists: [PackList]
    @AppStorage("cairn.unit") private var unit = "g"
    @AppStorage("cairn.confirmDeletes") private var confirmDeletes = true
    @State private var showNew = false
    @State private var newName = ""
    @State private var newTrip = ""
    @State private var pendingDelete: PackList?

    var body: some View {
        NavigationStack {
            Group {
                if lists.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "checklist",
                                       title: "No pack lists yet",
                                       message: "Create a list for your next trip and pull in gear from your catalog to see its weight.")
                            .padding(.top, 40)
                        Button { showNew = true } label: {
                            Label("New list", systemImage: "plus")
                        }.buttonStyle(InkButtonStyle()).padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(lists) { list in
                                NavigationLink { ListDetailView(list: list) } label: { listRow(list) }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            if confirmDeletes { pendingDelete = list } else { delete(list) }
                                        } label: { Label("Delete list", systemImage: "trash") }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Pack Lists")
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { newName = ""; newTrip = ""; showNew = true } label: { Image(systemName: "plus") }
                        .tint(Brand.text)
                }
            }
            .sheet(isPresented: $showNew) { newListSheet }
            .confirmationDialog("Delete this list? Your gear catalog is untouched.",
                                isPresented: Binding(get: { pendingDelete != nil },
                                                     set: { if !$0 { pendingDelete = nil } }),
                                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let l = pendingDelete { delete(l) } }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    private func listRow(_ list: PackList) -> some View {
        let w = PackMath.weights(for: list.entries)
        return HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(list.name).font(.headline).foregroundStyle(Brand.text)
                if !list.trip.isEmpty {
                    Text(list.trip).font(.subheadline).foregroundStyle(Brand.text2)
                }
                HStack(spacing: 8) {
                    Badge(text: "\(PackMath.itemCount(list.entries)) items")
                    Badge(text: "base " + WeightFmt.compact(w.base, unit: unit), color: Brand.live)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(WeightFmt.compact(w.totalPack, unit: unit))
                    .font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.text)
                Text("on back").font(Brand.mono(9)).foregroundStyle(Brand.text3)
            }
        }
        .glassCard()
    }

    private var newListSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "New pack list")
                        TextField("Name (e.g. JMT Section)", text: $newName).textFieldStyle(.roundedBorder)
                        TextField("Trip / dates (optional)", text: $newTrip).textFieldStyle(.roundedBorder)
                    }.glassCard()
                }
                .padding()
            }
            .navigationTitle("New list")
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showNew = false }.tint(Brand.text2) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { create() }.tint(Brand.text)
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func create() {
        let list = PackList(name: newName.trimmingCharacters(in: .whitespacesAndNewlines),
                            trip: newTrip.trimmingCharacters(in: .whitespacesAndNewlines))
        context.insert(list)
        try? context.save()
        Haptics.success()
        showNew = false
    }

    private func delete(_ l: PackList) {
        context.delete(l); try? context.save(); Haptics.warning(); pendingDelete = nil
    }
}

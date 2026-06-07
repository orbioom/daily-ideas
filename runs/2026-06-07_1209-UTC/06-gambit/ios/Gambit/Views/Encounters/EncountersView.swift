import SwiftUI
import SwiftData

struct EncountersView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Encounter.createdAt, order: .reverse) private var encounters: [Encounter]
    @AppStorage("gambit.confirmDeletes") private var confirmDeletes = true
    @State private var showNew = false
    @State private var newName = ""
    @State private var pendingDelete: Encounter?

    var body: some View {
        NavigationStack {
            Group {
                if encounters.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "shield.lefthalf.filled",
                                       title: "No encounters yet",
                                       message: "Create an encounter, add the party and their foes, and run initiative when the swords come out.")
                            .padding(.top, 40)
                        Button { newName = ""; showNew = true } label: {
                            Label("New encounter", systemImage: "plus")
                        }.buttonStyle(InkButtonStyle()).padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(encounters) { enc in
                                NavigationLink { EncounterRunView(encounter: enc) } label: { row(enc) }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            if confirmDeletes { pendingDelete = enc } else { delete(enc) }
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Encounters")
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { newName = ""; showNew = true } label: { Image(systemName: "plus") }.tint(Brand.text)
                }
            }
            .sheet(isPresented: $showNew) { newSheet }
            .confirmationDialog("Delete this encounter?", isPresented: Binding(
                get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let e = pendingDelete { delete(e) } }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    private func row(_ enc: Encounter) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(enc.name).font(.headline).foregroundStyle(Brand.text)
                    if enc.started { Badge(text: "Round \(enc.round)", color: Brand.live) }
                }
                HStack(spacing: 8) {
                    Badge(text: "\(enc.combatants.count) combatants")
                    if enc.aliveEnemies > 0 { Badge(text: "\(enc.aliveEnemies) foes", color: Brand.danger) }
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Brand.text3)
        }
        .glassCard()
    }

    private var newSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "New encounter")
                        TextField("Name (e.g. Goblin Ambush)", text: $newName).textFieldStyle(.roundedBorder)
                    }.glassCard()
                }.padding()
            }
            .navigationTitle("New encounter")
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
        let enc = Encounter(name: newName.trimmingCharacters(in: .whitespacesAndNewlines))
        context.insert(enc); try? context.save(); Haptics.success(); showNew = false
    }

    private func delete(_ e: Encounter) {
        context.delete(e); try? context.save(); Haptics.warning(); pendingDelete = nil
    }
}

import SwiftUI
import SwiftData

struct GuestsView: View {
    let wedding: Wedding
    @Environment(\.modelContext) private var context
    @Query(sort: \Guest.name) private var guests: [Guest]

    @State private var filter: RSVP? = nil
    @State private var search = ""
    @State private var showAdd = false
    @State private var editing: Guest?

    private var summary: WeddingEngine.GuestSummary { WeddingEngine.guestSummary(guests) }

    private var filtered: [Guest] {
        guests.filter { g in
            (filter == nil || g.rsvp == filter)
                && (search.isEmpty || g.name.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                VStack(spacing: 0) {
                    headcount
                    filterBar
                    if filtered.isEmpty {
                        Spacer()
                        EmptyStateView(icon: "person.2",
                                       title: guests.isEmpty ? "No guests yet" : "No matches",
                                       message: guests.isEmpty ? "Add the people you'd love to celebrate with."
                                                                : "Try another filter or search.")
                        Spacer()
                    } else {
                        List {
                            ForEach(filtered) { g in
                                Button { editing = g } label: { GuestRow(guest: g) }
                                    .buttonStyle(.plain)
                                    .listRowBackground(Color.white.opacity(0.001))
                                    .swipeActions(edge: .leading) {
                                        Button { setRSVP(g, .yes) } label: { Label("Yes", systemImage: "checkmark") }
                                            .tint(Brand.live)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) { delete(g) } label: { Label("Delete", systemImage: "trash") }
                                        Button { setRSVP(g, .no) } label: { Label("No", systemImage: "xmark") }.tint(Brand.danger)
                                    }
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .searchable(text: $search, prompt: "Search guests")
            .navigationTitle("Guests")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add guest")
                }
            }
            .sheet(isPresented: $showAdd) { GuestEditorView(mode: .create) }
            .sheet(item: $editing) { g in GuestEditorView(mode: .edit(g)) }
        }
    }

    private var headcount: some View {
        HStack(spacing: 0) {
            stat("\(summary.attendingHeads)", "yes", Brand.live)
            div
            stat("\(summary.maybeHeads)", "maybe", Brand.warn)
            div
            stat("\(summary.pendingHeads)", "pending", Brand.text3)
            div
            stat("\(summary.invitedHeads)", "invited", Brand.text)
        }
        .padding(.vertical, 10).padding(.horizontal, 12)
    }

    private var div: some View { Rectangle().fill(Brand.hairline).frame(width: 1, height: 28) }
    private func stat(_ v: String, _ l: String, _ tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(v).font(.headline).foregroundStyle(tint)
            Text(l).font(.caption2).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine).accessibilityLabel("\(l): \(v)")
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", active: filter == nil) { filter = nil }
                ForEach(RSVP.allCases) { r in
                    chip(r.title, active: filter == r) { filter = r }
                }
            }
            .padding(.horizontal, 12).padding(.bottom, 8)
        }
    }

    private func chip(_ title: String, active: Bool, _ action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(Brand.ease(0.2)) { action() }
            Haptics.selection()
        } label: {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(active ? AnyShapeStyle(Brand.inkGradient) : AnyShapeStyle(.ultraThinMaterial),
                            in: Capsule())
                .foregroundStyle(active ? Color.white : Brand.text2)
        }
        .buttonStyle(.plain)
    }

    private func setRSVP(_ g: Guest, _ r: RSVP) {
        g.rsvp = r; try? context.save(); Haptics.success()
    }
    private func delete(_ g: Guest) {
        context.delete(g); try? context.save(); Haptics.warning()
    }
}

struct GuestRow: View {
    let guest: Guest
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: guest.rsvp.icon).foregroundStyle(guest.rsvp.color).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(guest.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                HStack(spacing: 6) {
                    if guest.partySize > 1 {
                        Text("party of \(guest.partySize)").font(.caption2).foregroundStyle(Brand.text3)
                    }
                    if let t = guest.table {
                        Text("· \(t.name)").font(.caption2).foregroundStyle(Brand.text3)
                    }
                    if guest.meal != .none {
                        Text("· \(guest.meal.title)").font(.caption2).foregroundStyle(Brand.text3)
                    }
                }
            }
            Spacer()
            Text(guest.rsvp.title).font(.caption).foregroundStyle(guest.rsvp.color)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(guest.name), \(guest.rsvp.title), party of \(guest.partySize)")
    }
}

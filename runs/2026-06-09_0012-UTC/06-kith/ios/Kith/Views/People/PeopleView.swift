import SwiftUI
import SwiftData

struct PeopleView: View {
    @Query(sort: \Person.name) private var people: [Person]
    @State private var query = ""
    @State private var filter: Relationship?
    @State private var adding = false

    private var active: [Person] { people.filter { !$0.isArchived } }

    private var filtered: [Person] {
        active.filter { p in
            (filter == nil || p.relationship == filter) &&
            (query.isEmpty || p.name.localizedCaseInsensitiveContains(query))
        }
        .sorted { ($0.isFavorite ? 0 : 1, $0.name) < ($1.isFavorite ? 0 : 1, $1.name) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if active.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "person.2.fill",
                                       title: "No people yet",
                                       message: "Tap + to add the first person you'd like to stay close to.")
                            .glassCard().padding(20)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            if filtered.isEmpty {
                                Text("No one matches your filter.")
                                    .font(.subheadline).foregroundStyle(Brand.text3).padding(.top, 20)
                            } else {
                                ForEach(filtered) { person in
                                    NavigationLink(value: person) { personRow(person) }
                                        .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("People")
            .searchable(text: $query, prompt: "Search people")
            .navigationDestination(for: Person.self) { PersonDetailView(person: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button { filter = nil } label: {
                            Label("All", systemImage: filter == nil ? "checkmark" : "")
                        }
                        ForEach(Relationship.allCases) { rel in
                            Button { filter = rel } label: {
                                Label(rel.title, systemImage: filter == rel ? "checkmark" : rel.icon)
                            }
                        }
                    } label: { Image(systemName: "line.3.horizontal.decrease.circle") }
                        .accessibilityLabel("Filter by relationship")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); adding = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add person")
                }
            }
            .sheet(isPresented: $adding) { PersonEditorView(person: nil) }
        }
    }

    private func personRow(_ person: Person) -> some View {
        let days = KithEngine.daysSinceContact(for: person)
        let due = KithEngine.nextReachOut(for: person)
        let overdue = due.map { $0 < Calendar.current.startOfDay(for: .now) } ?? false
        return HStack(spacing: 14) {
            PersonAvatar(person: person, size: 50)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(person.name).font(.headline).foregroundStyle(Brand.text)
                    if person.isFavorite {
                        Image(systemName: "star.fill").font(.caption2).foregroundStyle(Brand.warn)
                            .accessibilityLabel("Favorite")
                    }
                }
                Text("\(person.relationship.title) · \(Format.sinceLabel(days))")
                    .font(.caption).foregroundStyle(overdue ? Brand.danger : Brand.text3)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(Brand.text3)
                .accessibilityHidden(true)
        }
        .glassCard()
        .accessibilityElement(children: .combine)
    }
}

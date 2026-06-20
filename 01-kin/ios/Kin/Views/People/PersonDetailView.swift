import SwiftUI
import SwiftData

struct PersonDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var person: Person

    @State private var showEdit = false
    @State private var showAddEvent = false
    @State private var showAddRelation = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection

                // Bio
                if !person.bio.isEmpty {
                    sectionCard(title: "Biography", icon: "doc.text") {
                        Text(person.bio)
                            .font(Font.kinBody)
                            .foregroundColor(KinTheme.label)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // Relationships
                if !person.parents.isEmpty || !person.spouses.isEmpty || !person.children.isEmpty || !person.siblings.isEmpty {
                    relationshipsSection
                }

                // Life Events
                if !person.lifeEvents.isEmpty {
                    lifeEventsSection
                }

                // Notes
                if !person.notes.isEmpty {
                    sectionCard(title: "Notes", icon: "note.text") {
                        Text(person.notes)
                            .font(Font.kinBody)
                            .foregroundColor(KinTheme.label)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .navigationTitle(person.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { showAddEvent = true }) {
                    Image(systemName: "calendar.badge.plus")
                }
                .accessibilityLabel("Add life event")
                Button(action: { showEdit = true }) {
                    Image(systemName: "pencil")
                }
                .accessibilityLabel("Edit person")
            }
        }
        .sheet(isPresented: $showEdit) {
            AddEditPersonView(person: person)
        }
        .sheet(isPresented: $showAddEvent) {
            AddEditEventView(person: person, event: nil)
        }
        .sheet(isPresented: $showAddRelation) {
            AddRelationshipView(person: person)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            PersonAvatarView(person: person, size: 88)

            Text(person.fullName)
                .font(Font.kinTitle)
                .foregroundColor(KinTheme.label)
                .multilineTextAlignment(.center)

            Text(person.gender.rawValue)
                .font(Font.kinCaption)
                .foregroundColor(KinTheme.secondaryLabel)
                .textCase(.uppercase)
                .tracking(1)

            HStack(spacing: 24) {
                if let birth = person.birthDate {
                    dateInfo(icon: "star.circle", label: "Born", date: birth, place: person.birthPlace)
                }
                if let death = person.deathDate {
                    dateInfo(icon: "moon.circle", label: "Died", date: death, place: person.deathPlace)
                }
            }

            if let age = person.age {
                Text(person.isDeceased ? "Lived \(age) years" : "Age \(age)")
                    .font(Font.kinBody)
                    .foregroundColor(KinTheme.secondaryLabel)
                    .accessibilityLabel(person.isDeceased ? "Lived \(age) years" : "Age \(age)")
            }
        }
        .padding(.top, 8)
    }

    private func dateInfo(icon: String, label: String, date: Date, place: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(KinTheme.accent)
                .accessibilityHidden(true)
            Text(label)
                .font(Font.kinCaption)
                .foregroundColor(KinTheme.secondaryLabel)
                .textCase(.uppercase)
                .tracking(1)
            Text(Self.dateFormatter.string(from: date))
                .font(Font.kinBody)
                .foregroundColor(KinTheme.label)
            if !place.isEmpty {
                Text(place)
                    .font(Font.kinCaption)
                    .foregroundColor(KinTheme.secondaryLabel)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(Self.dateFormatter.string(from: date))\(place.isEmpty ? "" : ", \(place)")")
    }

    private var relationshipsSection: some View {
        sectionCard(title: "Family", icon: "person.3") {
            VStack(spacing: 8) {
                relationGroup("Parents", people: person.parents)
                relationGroup("Spouses", people: person.spouses)
                relationGroup("Children", people: person.children)
                relationGroup("Siblings", people: person.siblings)

                Button(action: { showAddRelation = true }) {
                    Label("Add Relationship", systemImage: "link.badge.plus")
                        .font(Font.kinBody)
                        .foregroundColor(KinTheme.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityLabel("Add a relationship")
            }
        }
    }

    @ViewBuilder
    private func relationGroup(_ title: String, people: [Person]) -> some View {
        if !people.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(Font.kinCaption)
                    .foregroundColor(KinTheme.secondaryLabel)
                    .textCase(.uppercase)
                    .tracking(1)
                ForEach(people) { rel in
                    NavigationLink(value: rel) {
                        HStack(spacing: 8) {
                            PersonAvatarView(person: rel, size: 32)
                            Text(rel.fullName)
                                .font(Font.kinBody)
                                .foregroundColor(KinTheme.label)
                        }
                    }
                }
            }
            Divider()
        }
    }

    private var lifeEventsSection: some View {
        sectionCard(title: "Life Events", icon: "calendar") {
            VStack(spacing: 10) {
                ForEach(person.sortedLifeEvents) { event in
                    EventRowView(event: event)
                }
                Button(action: { showAddEvent = true }) {
                    Label("Add Event", systemImage: "plus.circle")
                        .font(Font.kinBody)
                        .foregroundColor(KinTheme.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityLabel("Add a life event")
            }
        }
    }

    private func sectionCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(Font.kinHeadline)
                .foregroundColor(KinTheme.brown)
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .accessibilityElement(children: .contain)
    }
}

struct EventRowView: View {
    let event: LifeEvent

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: event.category.icon)
                .font(.body)
                .foregroundColor(KinTheme.accent)
                .frame(width: 22)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(Font.kinBody)
                    .foregroundColor(KinTheme.label)
                if let date = event.date {
                    Text((event.dateIsApproximate ? "~" : "") + Self.dateFormatter.string(from: date))
                        .font(Font.kinCaption)
                        .foregroundColor(KinTheme.secondaryLabel)
                }
                if !event.location.isEmpty {
                    Text(event.location)
                        .font(Font.kinCaption)
                        .foregroundColor(KinTheme.secondaryLabel)
                }
                if !event.description.isEmpty {
                    Text(event.description)
                        .font(Font.kinCaption)
                        .foregroundColor(KinTheme.secondaryLabel)
                        .lineLimit(2)
                }
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.category.rawValue): \(event.title)")
    }
}

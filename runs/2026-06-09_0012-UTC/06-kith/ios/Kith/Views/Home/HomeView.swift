import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query private var people: [Person]
    @AppStorage("kith.soonWindow") private var soonWindow = 3
    @AppStorage("kith.occasionWindow") private var occasionWindow = 30
    @State private var logPerson: Person?

    private var reachOuts: [KithEngine.ReachOut] {
        KithEngine.reachOuts(for: people, soonWindow: soonWindow)
    }
    private var occasions: [KithEngine.Occasion] {
        KithEngine.upcomingOccasions(for: people, withinDays: occasionWindow)
    }

    var body: some View {
        NavigationStack {
            Group {
                if people.filter({ !$0.isArchived }).isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "person.2",
                                       title: "No one here yet",
                                       message: "Add the people you care about in the People tab, then Kith helps you keep in touch.")
                            .glassCard().padding(20)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            reachOutCard
                            occasionsCard
                        }
                        .padding(20)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Today")
            .navigationDestination(for: Person.self) { PersonDetailView(person: $0) }
            .sheet(item: $logPerson) { InteractionSheet(person: $0) }
        }
    }

    private var reachOutCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "bell.badge.fill").foregroundStyle(Brand.magic)
                    Eyebrow(text: "Reach out")
                    Spacer()
                    if !reachOuts.isEmpty {
                        Text("\(reachOuts.count)").font(Brand.mono(13)).foregroundStyle(Brand.text3)
                    }
                }
                if reachOuts.isEmpty {
                    Text("You're all caught up. Lovely.")
                        .font(.subheadline).foregroundStyle(Brand.text2).padding(.vertical, 6)
                } else {
                    ForEach(reachOuts) { item in
                        HStack(spacing: 12) {
                            NavigationLink(value: item.person) {
                                HStack(spacing: 12) {
                                    PersonAvatar(person: item.person, size: 40)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.person.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                                        Text("\(item.person.relationship.title) · \(KithEngine.dueLabel(item.daysUntil))")
                                            .font(.caption)
                                            .foregroundStyle(item.bucket == .overdue ? Brand.danger : Brand.text3)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            Spacer()
                            Button {
                                Haptics.tap(); logPerson = item.person
                            } label: {
                                Image(systemName: "checkmark.circle.fill").font(.title2).foregroundStyle(item.person.color.color)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Log contact with \(item.person.name)")
                        }
                        .padding(.vertical, 3)
                    }
                }
            }
        }
    }

    private var occasionsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar.badge.clock").foregroundStyle(Brand.info)
                    Eyebrow(text: "Upcoming occasions")
                }
                if occasions.isEmpty {
                    Text("No birthdays or anniversaries in the next \(occasionWindow) days.")
                        .font(.subheadline).foregroundStyle(Brand.text3).padding(.vertical, 6)
                } else {
                    ForEach(occasions) { occ in
                        NavigationLink(value: occ.person) {
                            HStack(spacing: 12) {
                                Image(systemName: occ.date.kind.icon)
                                    .foregroundStyle(occ.person.color.color).frame(width: 26)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(occ.person.name) · \(occ.date.title)")
                                        .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                                    Text(occasionSubtitle(occ)).font(.caption).foregroundStyle(Brand.text3)
                                }
                                Spacer()
                                Text(KithEngine.occasionLabel(occ.daysUntil))
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(occ.daysUntil <= 1 ? Brand.warn : Brand.text2)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 3)
                    }
                }
            }
        }
    }

    private func occasionSubtitle(_ occ: KithEngine.Occasion) -> String {
        var s = Format.monthDay.string(from: occ.occurrence)
        if let turning = occ.turning {
            s += occ.date.kind == .birthday ? " · turning \(turning)" : " · \(turning) years"
        }
        return s
    }
}

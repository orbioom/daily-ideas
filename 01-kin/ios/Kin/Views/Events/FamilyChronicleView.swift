import SwiftUI
import SwiftData

struct FamilyChronicleView: View {
    @Query(sort: \LifeEvent.createdAt) private var allEvents: [LifeEvent]
    @State private var selectedCategory: LifeEventCategory?
    @State private var search = ""

    private static let yearFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy"; return f
    }()

    var filtered: [LifeEvent] {
        var events = allEvents.filter { $0.person != nil }
        if let cat = selectedCategory { events = events.filter { $0.category == cat } }
        if !search.isEmpty {
            events = events.filter {
                $0.title.localizedCaseInsensitiveContains(search) ||
                ($0.person?.fullName.localizedCaseInsensitiveContains(search) ?? false)
            }
        }
        return events.sorted {
            ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture)
        }
    }

    var groupedByYear: [(String, [LifeEvent])] {
        let withDate = filtered.filter { $0.date != nil }
        let noDate = filtered.filter { $0.date == nil }
        var groups: [String: [LifeEvent]] = [:]
        for event in withDate {
            let year = Self.yearFormatter.string(from: event.date!)
            groups[year, default: []].append(event)
        }
        var result = groups.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
        if !noDate.isEmpty { result.append(("No Date", noDate)) }
        return result
    }

    var body: some View {
        NavigationStack {
            Group {
                if allEvents.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        categoryFilter
                        if filtered.isEmpty {
                            Spacer()
                            Text("No events match your filter.")
                                .font(Font.kinBody)
                                .foregroundColor(KinTheme.secondaryLabel)
                            Spacer()
                        } else {
                            List {
                                ForEach(groupedByYear, id: \.0) { year, events in
                                    Section(header: Text(year)
                                        .font(Font.kinHeadline)
                                        .foregroundColor(KinTheme.brown)) {
                                        ForEach(events) { event in
                                            ChronicleEventRow(event: event)
                                        }
                                    }
                                }
                            }
                            .listStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Family Chronicle")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $search, prompt: "Search events or names")
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", icon: "list.bullet", selected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(LifeEventCategory.allCases, id: \.self) { cat in
                    FilterChip(label: cat.rawValue, icon: cat.icon, selected: selectedCategory == cat) {
                        selectedCategory = selectedCategory == cat ? nil : cat
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 56))
                .foregroundColor(KinTheme.sepia)
                .accessibilityHidden(true)
            Text("No Events Yet")
                .font(Font.kinHeadline)
                .foregroundColor(KinTheme.label)
            Text("Add life events to people\nto build your family chronicle.")
                .font(Font.kinBody)
                .foregroundColor(KinTheme.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct FilterChip: View {
    let label: String
    let icon: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(selected ? KinTheme.accent : Color(uiColor: .secondarySystemBackground))
                )
                .foregroundColor(selected ? .white : KinTheme.secondaryLabel)
        }
        .accessibilityLabel(label + (selected ? ", selected" : ""))
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

struct ChronicleEventRow: View {
    let event: LifeEvent

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: event.category.icon)
                .font(.body)
                .foregroundColor(KinTheme.accent)
                .frame(width: 22)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(event.title)
                        .font(Font.kinBody)
                        .foregroundColor(KinTheme.label)
                    Spacer()
                    if let person = event.person {
                        Text(person.firstName)
                            .font(Font.kinCaption)
                            .foregroundColor(KinTheme.accent)
                    }
                }
                if let date = event.date {
                    Text((event.dateIsApproximate ? "~" : "") + Self.dateFormatter.string(from: date))
                        .font(Font.kinCaption)
                        .foregroundColor(KinTheme.secondaryLabel)
                }
                if !event.location.isEmpty {
                    Label(event.location, systemImage: "mappin")
                        .font(Font.kinCaption)
                        .foregroundColor(KinTheme.secondaryLabel)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.category.rawValue): \(event.title)\(event.person.map { ", \($0.fullName)" } ?? "")")
    }
}

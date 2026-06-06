import SwiftUI
import SwiftData

/// The Climbs tab: a browser of all logged climbs with a Projects filter and a
/// discipline filter. Each climb links to its detail.
struct ClimbsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Query(sort: \Climb.createdAt, order: .reverse) private var climbs: [Climb]

    enum Filter: String, CaseIterable, Identifiable {
        case all, projects, sent
        var id: String { rawValue }
        var title: String {
            switch self {
            case .all: return "All"
            case .projects: return "Projects"
            case .sent: return "Sent"
            }
        }
    }

    @State private var filter: Filter = .all
    @State private var showingEditor = false
    @State private var newClimb: Climb?

    private var filtered: [Climb] {
        switch filter {
        case .all: return climbs
        case .projects: return climbs.filter { $0.isProject }
        case .sent: return climbs.filter { $0.isSent }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                if climbs.isEmpty {
                    EmptyStateView(
                        icon: "mountain.2",
                        title: "No climbs yet",
                        message: "Add the boulders and routes you're working on. Mark the hard ones as projects to track your progress.",
                        actionTitle: "Add a climb",
                        action: { startNewClimb() }
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            ChipPicker(options: Filter.allCases, title: \.title, selection: $filter)
                                .padding(.horizontal, 16)

                            if filtered.isEmpty {
                                Text(emptyFilterMessage)
                                    .font(.subheadline)
                                    .foregroundStyle(Brand.text2)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                                    .padding(.top, 40)
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(filtered) { climb in
                                        NavigationLink(value: climb) {
                                            ClimbRow(climb: climb)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Climbs")
            .navigationDestination(for: Climb.self) { climb in
                ClimbDetailView(climb: climb)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { startNewClimb() } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add climb")
                }
            }
            .sheet(isPresented: $showingEditor) {
                if let newClimb {
                    ClimbEditView(climb: newClimb, isNew: true)
                }
            }
        }
    }

    private var emptyFilterMessage: String {
        switch filter {
        case .all: return "No climbs."
        case .projects: return "No active projects. Mark a climb as a project to see it here."
        case .sent: return "No sends recorded yet. Log a successful attempt to populate this list."
        }
    }

    private func startNewClimb() {
        let climb = Climb(discipline: settings.defaultDiscipline,
                          location: defaultLocation())
        context.insert(climb)
        newClimb = climb
        showingEditor = true
    }

    private func defaultLocation() -> Location? {
        guard let id = UUID(uuidString: settings.defaultLocationID) else { return nil }
        let descriptor = FetchDescriptor<Location>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }
}

/// A single climb row card.
struct ClimbRow: View {
    @Environment(SettingsStore.self) private var settings
    var climb: Climb

    private var grade: String {
        climb.gradeLabel(boulderSystem: settings.boulderSystem, routeSystem: settings.routeSystem)
    }

    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                if climb.hasColor {
                    HoldColorDot(index: climb.colorIndex, size: 16)
                } else {
                    Image(systemName: climb.discipline.symbol)
                        .font(.system(size: 16))
                        .foregroundStyle(Brand.text3)
                        .frame(width: 16)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(climb.displayName)
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(climb.discipline.title)
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                        if let location = climb.location {
                            Text("· \(location.name)")
                                .font(.caption)
                                .foregroundStyle(Brand.text3)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 6) {
                    GradePill(label: grade)
                    if climb.isProject && !climb.isSent {
                        Label("Project", systemImage: "flag")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Brand.project)
                            .labelStyle(.titleAndIcon)
                    } else if climb.isSent {
                        Label("Sent", systemImage: "checkmark")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Brand.send)
                            .labelStyle(.titleAndIcon)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(climb.displayName), \(climb.discipline.title), grade \(grade)\(climb.isProject && !climb.isSent ? ", project" : "")\(climb.isSent ? ", sent" : "")")
    }
}

#Preview {
    ClimbsView()
        .environment(SettingsStore())
        .modelContainer(for: [Location.self, Climb.self, Session.self, Attempt.self], inMemory: true)
}

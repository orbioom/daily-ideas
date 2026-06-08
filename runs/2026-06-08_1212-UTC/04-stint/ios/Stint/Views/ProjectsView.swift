import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Client.name) private var clients: [Client]
    @Query(sort: \Project.name) private var projects: [Project]
    @AppStorage("defaultCurrency") private var currency = Locale.current.currency?.identifier ?? "USD"

    @State private var editingClient: Client?
    @State private var editingProject: Project?

    private let engine = TimeEngine()

    private var noClientProjects: [Project] { projects.filter { $0.client == nil } }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if clients.isEmpty && projects.isEmpty {
                    EmptyStateView(
                        icon: "folder",
                        title: "No clients or projects",
                        message: "Add a client with an hourly rate, then projects under it. Time you track rolls up here."
                    )
                } else {
                    List {
                        ForEach(clients) { client in
                            Section {
                                ForEach(client.projects.sorted { $0.name < $1.name }) { p in
                                    projectRow(p)
                                }
                                Button {
                                    addProject(to: client)
                                } label: {
                                    Label("Add project", systemImage: "plus.circle").font(.subheadline)
                                }
                            } header: {
                                clientHeader(client)
                            }
                        }
                        if !noClientProjects.isEmpty {
                            Section("No client") {
                                ForEach(noClientProjects) { p in projectRow(p) }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { addClient() } label: { Label("New client", systemImage: "person.badge.plus") }
                        Button { addProject(to: nil) } label: { Label("New project", systemImage: "folder.badge.plus") }
                    } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add")
                }
            }
            .sheet(item: $editingClient) { ClientEditorView(client: $0) }
            .sheet(item: $editingProject) { ProjectEditorView(project: $0) }
        }
    }

    private func clientHeader(_ client: Client) -> some View {
        HStack {
            Circle().fill(Color(hex: client.colorHex)).frame(width: 9, height: 9)
            Text(client.name)
            Spacer()
            if client.hourlyRate > 0 {
                Text("\(Money.compact(client.hourlyRate, code: currency))/h")
                    .font(Brand.mono(10))
            }
            Button { editingClient = client } label: { Image(systemName: "pencil").font(.caption) }
                .accessibilityLabel("Edit \(client.name)")
        }
    }

    private func projectRow(_ p: Project) -> some View {
        Button { editingProject = p } label: {
            HStack(spacing: 12) {
                Circle().fill(Color(hex: p.colorHex)).frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 2) {
                    Text(p.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                    Text(detailText(p)).font(.caption).foregroundStyle(Brand.text3)
                }
                Spacer()
                Text(DurationFormat.compact(engine.totalSeconds(p.entries)))
                    .font(Brand.mono(12)).foregroundStyle(Brand.text2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions {
            Button(role: .destructive) { context.delete(p); Haptics.warning() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func detailText(_ p: Project) -> String {
        guard p.billable else { return "Non-billable" }
        let rate = p.effectiveRate
        return rate > 0 ? "\(Money.compact(rate, code: currency))/h" : "No rate set"
    }

    private func addClient() {
        Haptics.tap()
        let c = Client(name: "")
        context.insert(c); editingClient = c
    }

    private func addProject(to client: Client?) {
        Haptics.tap()
        let p = Project(name: "", colorHex: client?.colorHex ?? 0x3E8E7E, client: client)
        context.insert(p); editingProject = p
    }
}

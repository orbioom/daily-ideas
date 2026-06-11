import SwiftUI
import SwiftData

struct PipelineView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Query(sort: \Application.createdAt, order: .reverse) private var applications: [Application]

    @State private var filter: StageFilter = .active
    @State private var search = ""
    @State private var showEditor = false

    enum StageFilter: String, CaseIterable, Identifiable {
        case active = "Active"
        case wishlist = "Wishlist"
        case offers = "Offers"
        case closed = "Closed"
        case all = "All"
        var id: String { rawValue }
    }

    private var filtered: [Application] {
        let base: [Application]
        switch filter {
        case .active:
            base = applications.filter { !$0.stage.isClosed && $0.stage != .wishlist }
        case .wishlist:
            base = applications.filter { $0.stage == .wishlist }
        case .offers:
            base = applications.filter { $0.stage == .offer || $0.stage == .accepted }
        case .closed:
            base = applications.filter { $0.stage.isClosed }
        case .all:
            base = applications
        }
        let trimmed = search.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return base }
        return base.filter {
            $0.company.localizedCaseInsensitiveContains(trimmed) ||
            $0.role.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if applications.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "tray",
                                       title: "No applications yet",
                                       message: "Tap + to log your first application — or add dream companies to your wishlist before you apply.")
                        Button {
                            showEditor = true
                        } label: {
                            Label("Add application", systemImage: "plus")
                                .font(.headline)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.blue)
                    }
                } else {
                    List {
                        Section {
                            ForEach(filtered) { app in
                                NavigationLink(value: app) {
                                    row(app)
                                }
                            }
                            .onDelete { offsets in
                                for i in offsets { context.delete(filtered[i]) }
                            }
                        } header: {
                            if !filtered.isEmpty {
                                Text("\(filtered.count) application\(filtered.count == 1 ? "" : "s")")
                            }
                        }
                        if filtered.isEmpty {
                            EmptyStateView(icon: "line.3.horizontal.decrease.circle",
                                           title: "Nothing here",
                                           message: "No applications match this filter\(search.isEmpty ? "" : " and search").")
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .searchable(text: $search, prompt: "Company or role")
                }
            }
            .background(Theme.background(scheme))
            .navigationTitle("Pipeline")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Picker("Filter", selection: $filter) {
                        ForEach(StageFilter.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.menu)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add application")
                }
            }
            .navigationDestination(for: Application.self) { app in
                ApplicationDetailView(application: app)
            }
            .sheet(isPresented: $showEditor) {
                ApplicationEditorView(application: nil)
            }
        }
    }

    private func row(_ app: Application) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.stageColor(app.stage).opacity(0.15))
                Text(initials(app.company))
                    .font(.headline)
                    .foregroundStyle(Theme.stageColor(app.stage))
            }
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(app.company)
                    .font(Theme.display(17, weight: .semibold))
                    .foregroundStyle(Theme.ink(scheme))
                Text(app.role)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft(scheme))
                HStack(spacing: 6) {
                    StageChip(stage: app.stage)
                    if app.excitement >= 4 {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .accessibilityLabel("High excitement")
                    }
                }
            }
            Spacer()
            Text(FunnelEngine.daysAgoLabel(app.lastActivity))
                .font(.caption2)
                .foregroundStyle(Theme.inkSoft(scheme))
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(app.company), \(app.role), stage \(app.stage.label), last activity \(FunnelEngine.daysAgoLabel(app.lastActivity))")
    }

    private func initials(_ name: String) -> String {
        let words = name.split(separator: " ").prefix(2)
        let letters = words.compactMap { $0.first.map(String.init) }
        return letters.isEmpty ? "?" : letters.joined().uppercased()
    }
}

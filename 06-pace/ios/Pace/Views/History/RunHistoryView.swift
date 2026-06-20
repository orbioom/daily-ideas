import SwiftUI
import SwiftData

struct RunHistoryView: View {
    @Query(sort: \RunSession.date, order: .reverse) private var sessions: [RunSession]
    @AppStorage("pace_use_km") private var useKm = true
    @Environment(\.modelContext) private var modelContext

    @State private var filterType: ActivityType? = nil
    @State private var sessionToDelete: RunSession? = nil
    @State private var showDeleteConfirm = false

    private var filteredSessions: [RunSession] {
        guard let filter = filterType else { return sessions }
        return sessions.filter { $0.activityType == filter }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    EmptyHistoryState()
                } else {
                    List {
                        // Filter picker
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChip(title: "All", isSelected: filterType == nil) {
                                    filterType = nil
                                }
                                ForEach(ActivityType.allCases, id: \.self) { type in
                                    FilterChip(
                                        title: type.rawValue,
                                        isSelected: filterType == type
                                    ) {
                                        filterType = (filterType == type) ? nil : type
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                        .listRowSeparator(.hidden)

                        ForEach(filteredSessions) { session in
                            NavigationLink(destination: RunDetailView(session: session)) {
                                RunCard(session: session, useKm: useKm)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    sessionToDelete = session
                                    showDeleteConfirm = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("History")
            .alert("Delete Activity?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    if let session = sessionToDelete {
                        modelContext.delete(session)
                        try? modelContext.save()
                    }
                    sessionToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    sessionToDelete = nil
                }
            } message: {
                Text("This activity will be permanently deleted.")
            }
        }
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .black : PaceTheme.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? PaceTheme.accent : PaceTheme.surface
                )
                .clipShape(Capsule())
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct EmptyHistoryState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 60))
                .foregroundStyle(PaceTheme.accent.opacity(0.6))
            Text("No activities yet")
                .font(.headline)
            Text("Your completed runs, walks and hikes will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

import SwiftUI
import SwiftData

struct ClientListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Client.name) private var clients: [Client]
    @State private var searchText = ""
    @State private var showingEditor = false
    @State private var clientToDelete: Client?
    @State private var showDeleteConfirmation = false

    var filteredClients: [Client] {
        if searchText.isEmpty { return clients }
        return clients.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.company.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if clients.isEmpty {
                    ClientEmptyStateView(onAdd: { showingEditor = true })
                } else {
                    List {
                        ForEach(filteredClients) { client in
                            NavigationLink(destination: ClientDetailView(client: client)) {
                                ClientCard(client: client)
                                    .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: confirmDelete)
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $searchText, prompt: "Search clients")
                }
            }
            .navigationTitle("Clients")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Add new client")
                }
            }
            .sheet(isPresented: $showingEditor) {
                ClientEditorView(client: nil)
            }
            .confirmationDialog(
                "Delete Client",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let client = clientToDelete {
                        modelContext.delete(client)
                        try? modelContext.save()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will also delete all invoices for this client. This action cannot be undone.")
            }
        }
    }

    private func confirmDelete(at offsets: IndexSet) {
        if let first = offsets.first {
            clientToDelete = filteredClients[first]
            showDeleteConfirmation = true
        }
    }
}

private struct ClientEmptyStateView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2")
                .font(.system(size: 56))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No Clients Yet")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Add your first client to start creating invoices.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Add Client") {
                onAdd()
            }
            .buttonStyle(.borderedProminent)
            .tint(BriefTheme.accent)
            .accessibilityLabel("Add your first client")
        }
        .padding()
    }
}

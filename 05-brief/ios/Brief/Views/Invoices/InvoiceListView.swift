import SwiftUI
import SwiftData

struct InvoiceListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Invoice.issueDate, order: .reverse) private var invoices: [Invoice]
    @Query private var clients: [Client]
    @State private var selectedFilter: InvoiceStatus? = nil
    @State private var showingEditor = false
    @State private var showNoClientsAlert = false
    @State private var invoiceToDelete: Invoice?
    @State private var showDeleteConfirmation = false

    var filteredInvoices: [Invoice] {
        guard let filter = selectedFilter else { return invoices }
        return invoices.filter { $0.displayStatus == filter }
    }

    var body: some View {
        NavigationStack {
            Group {
                if invoices.isEmpty {
                    InvoiceEmptyStateView(onAdd: { handleAddTap() })
                } else {
                    VStack(spacing: 0) {
                        // Filter picker
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChip(label: "All", isSelected: selectedFilter == nil) {
                                    selectedFilter = nil
                                }
                                ForEach(InvoiceStatus.allCases, id: \.self) { status in
                                    FilterChip(
                                        label: status.rawValue,
                                        isSelected: selectedFilter == status,
                                        color: BriefTheme.statusColor(for: status)
                                    ) {
                                        selectedFilter = selectedFilter == status ? nil : status
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                        .background(Color(.systemGroupedBackground))

                        if filteredInvoices.isEmpty {
                            Spacer()
                            Text("No \(selectedFilter?.rawValue ?? "") invoices")
                                .foregroundColor(.secondary)
                            Spacer()
                        } else {
                            List {
                                ForEach(filteredInvoices) { invoice in
                                    NavigationLink(destination: InvoiceDetailView(invoice: invoice)) {
                                        InvoiceCard(invoice: invoice)
                                            .padding(.vertical, 4)
                                    }
                                }
                                .onDelete(perform: confirmDelete)
                            }
                            .listStyle(.insetGrouped)
                        }
                    }
                }
            }
            .navigationTitle("Invoices")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        handleAddTap()
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Create new invoice")
                }
            }
            .sheet(isPresented: $showingEditor) {
                InvoiceEditorView(invoice: nil)
            }
            .alert("No Clients", isPresented: $showNoClientsAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please add at least one client before creating an invoice.")
            }
            .confirmationDialog(
                "Delete Invoice",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let invoice = invoiceToDelete {
                        modelContext.delete(invoice)
                        try? modelContext.save()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private func handleAddTap() {
        if clients.isEmpty {
            showNoClientsAlert = true
        } else {
            showingEditor = true
        }
    }

    private func confirmDelete(at offsets: IndexSet) {
        if let first = offsets.first {
            invoiceToDelete = filteredInvoices[first]
            showDeleteConfirmation = true
        }
    }
}

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? (color == .primary ? BriefTheme.accent : color).opacity(0.15) : Color(.tertiarySystemBackground))
                .foregroundColor(isSelected ? (color == .primary ? BriefTheme.accent : color) : .secondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? (color == .primary ? BriefTheme.accent : color).opacity(0.4) : Color.clear, lineWidth: 1)
                )
        }
        .accessibilityLabel("Filter by \(label)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct InvoiceEmptyStateView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 56))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No Invoices Yet")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Create your first invoice to start tracking your work.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Create Invoice") {
                onAdd()
            }
            .buttonStyle(.borderedProminent)
            .tint(BriefTheme.accent)
            .accessibilityLabel("Create your first invoice")
        }
        .padding()
    }
}

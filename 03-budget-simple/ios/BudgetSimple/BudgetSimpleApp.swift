import SwiftUI
import SwiftData

@Model final class Envelope {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var budget: Double
    @Relationship(deleteRule: .cascade) var transactions: [Transaction] = []

    var spent: Double { transactions.reduce(0) { $0 + $1.amount } }
    var remaining: Double { budget - spent }
}

@Model final class Transaction {
    @Attribute(.unique) var id: UUID = UUID()
    var date: Date
    var amount: Double
    var note: String = ""
    var category: String = ""
}

@main
struct BudgetSimpleApp: App {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false

    var modelContainer: ModelContainer = {
        let schema = Schema([Envelope.self, Transaction.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                MainView()
            } else {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
            }
        }
        .modelContainer(modelContainer)
    }
}

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool

    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            Text("💰").font(.system(size: 80))
            VStack {
                Text("Budget Simple")
                    .font(.title).fontWeight(.bold)
                Text("Zero-based budgeting that actually works")
                    .font(.body).foregroundColor(.secondary).multilineTextAlignment(.center)
            }
            Spacer()
            Button(action: { hasSeenOnboarding = true }) {
                Text("Get Started").frame(maxWidth: .infinity).padding().background(Color.accentColor).foregroundColor(.white).cornerRadius(8)
            }
        }
        .padding()
    }
}

struct MainView: View {
    @Query var envelopes: [Envelope]
    @State var showAddEnvelope = false

    var totalBudget: Double { envelopes.reduce(0) { $0 + $1.budget } }
    var totalSpent: Double { envelopes.reduce(0) { $0 + $1.spent } }
    var totalRemaining: Double { totalBudget - totalSpent }

    var body: some View {
        TabView {
            NavigationStack {
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Spent").font(.caption).foregroundColor(.secondary)
                                Text("$\(String(format: "%.2f", totalSpent))").font(.title2).fontWeight(.bold)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Budget").font(.caption).foregroundColor(.secondary)
                                Text("$\(String(format: "%.2f", totalBudget))").font(.title2).fontWeight(.bold)
                            }
                        }
                        ProgressView(value: totalSpent / max(totalBudget, 0.1)).tint(.accentColor)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)

                    if envelopes.isEmpty {
                        VStack {
                            Text("No envelopes yet").font(.headline)
                            Text("Create one to start budgeting").font(.body).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(envelopes) { envelope in
                                NavigationLink(destination: EnvelopeDetailView(envelope: envelope)) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(envelope.name).font(.headline)
                                        HStack {
                                            Text("$\(String(format: "%.2f", envelope.spent))").font(.caption)
                                            Spacer()
                                            Text("$\(String(format: "%.2f", envelope.budget))").font(.caption).foregroundColor(.secondary)
                                        }
                                        ProgressView(value: envelope.spent / max(envelope.budget, 0.1)).tint(.accentColor)
                                    }
                                }
                            }
                            .onDelete { indices in
                                indices.forEach { _ in }
                            }
                        }
                    }
                }
                .padding()
                .navigationTitle("Budget")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showAddEnvelope = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .tabItem { Label("Budgets", systemImage: "wallet.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .sheet(isPresented: $showAddEnvelope) {
            AddEnvelopeView()
        }
    }
}

struct EnvelopeDetailView: View {
    let envelope: Envelope
    @State var showAddTransaction = false

    var body: some View {
        VStack {
            VStack(spacing: 8) {
                Text(envelope.name).font(.headline)
                HStack {
                    Text("$\(String(format: "%.2f", envelope.spent))").font(.title2).fontWeight(.bold)
                    Spacer()
                    Text("of $\(String(format: "%.2f", envelope.budget))").font(.caption).foregroundColor(.secondary)
                }
                ProgressView(value: envelope.spent / max(envelope.budget, 0.1)).tint(envelope.remaining < 0 ? .red : .accentColor)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)

            List {
                ForEach(envelope.transactions.sorted { $0.date > $1.date }) { txn in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(txn.note).font(.headline)
                            Text(txn.date.formatted(date: .abbreviated, time: .omitted)).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("$\(String(format: "%.2f", txn.amount))").font(.body).fontWeight(.bold)
                    }
                }
            }

            Button(action: { showAddTransaction = true }) {
                Text("Add Transaction").frame(maxWidth: .infinity).padding().background(Color.accentColor).foregroundColor(.white).cornerRadius(8)
            }
            .padding()
        }
        .navigationTitle(envelope.name)
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView(envelope: envelope)
        }
    }
}

struct AddEnvelopeView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @State var name = ""
    @State var budget = 0.0

    var body: some View {
        NavigationStack {
            Form {
                TextField("Envelope name", text: $name)
                HStack {
                    Text("$")
                    TextField("Budget", value: $budget, format: .number)
                }
            }
            .navigationTitle("New Envelope")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let envelope = Envelope(name: name, budget: budget)
                        modelContext.insert(envelope)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct AddTransactionView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    let envelope: Envelope
    @State var amount = 0.0
    @State var note = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Description", text: $note)
                HStack {
                    Text("$")
                    TextField("Amount", value: $amount, format: .number)
                }
            }
            .navigationTitle("Add Transaction")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let txn = Transaction(date: Date(), amount: amount, note: note)
                        envelope.transactions.append(txn)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

import SwiftUI
import SwiftData

@Model final class Portfolio {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    @Relationship(deleteRule: .cascade) var holdings: [Holding] = []
}

@Model final class Holding {
    @Attribute(.unique) var id: UUID = UUID()
    var symbol: String
    var quantity: Double
    var costBasis: Double
    var currentPrice: Double
    var date: Date

    var marketValue: Double { quantity * currentPrice }
    var gain: Double { marketValue - costBasis }
    var gainPercent: Double { (gain / max(costBasis, 0.01)) * 100 }
}

@main
struct PortfolioPulseApp: App {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false

    var modelContainer: ModelContainer = {
        let schema = Schema([Portfolio.self, Holding.self])
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
            Text("📈").font(.system(size: 80))
            VStack {
                Text("Portfolio Pulse")
                    .font(.title).fontWeight(.bold)
                Text("Track your investments with AI insights")
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
    @Query var portfolios: [Portfolio]
    @State var showAddPortfolio = false

    var totalValue: Double { portfolios.flatMap { $0.holdings }.reduce(0) { $0 + $1.marketValue } }
    var totalGain: Double { portfolios.flatMap { $0.holdings }.reduce(0) { $0 + $1.gain } }
    var totalGainPercent: Double { (totalGain / max(totalValue - totalGain, 0.01)) * 100 }

    var body: some View {
        TabView {
            NavigationStack {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("Portfolio Value").font(.caption).foregroundColor(.secondary)
                        Text("$\(String(format: "%.2f", totalValue))").font(.title).fontWeight(.bold)
                        HStack {
                            Text("Gain: $\(String(format: "%.2f", totalGain))").font(.caption)
                            Text("\(String(format: "%.1f", totalGainPercent))%").font(.caption).foregroundColor(totalGain >= 0 ? .green : .red)
                        }
                    }
                    .frame(maxWidth: .infinity).padding().background(Color(.systemBackground)).cornerRadius(8)

                    if portfolios.isEmpty {
                        VStack {
                            Text("No holdings yet").font(.headline)
                            Text("Add your first investment to get started").font(.body).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(portfolios) { portfolio in
                                Section(portfolio.name) {
                                    ForEach(portfolio.holdings) { holding in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(holding.symbol).font(.headline).monospaced()
                                                Text("\(String(format: "%.2f", holding.quantity)) shares").font(.caption).foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            VStack(alignment: .trailing, spacing: 4) {
                                                Text("$\(String(format: "%.2f", holding.marketValue))").font(.headline)
                                                Text("\(String(format: "%+.1f", holding.gainPercent))%").font(.caption).foregroundColor(holding.gain >= 0 ? .green : .red)
                                            }
                                        }
                                    }
                                    .onDelete { indices in
                                        indices.forEach { _ in }
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Portfolio")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showAddPortfolio = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .tabItem { Label("Holdings", systemImage: "chart.pie.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .sheet(isPresented: $showAddPortfolio) {
            AddPortfolioView()
        }
    }
}

struct AddPortfolioView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @State var name = ""
    @State var symbol = ""
    @State var quantity = 0.0
    @State var price = 0.0

    var body: some View {
        NavigationStack {
            Form {
                TextField("Portfolio name", text: $name)
                Section("First Holding") {
                    TextField("Symbol", text: $symbol).textCase(.uppercase)
                    HStack {
                        Text("Qty")
                        TextField("Quantity", value: $quantity, format: .number)
                    }
                    HStack {
                        Text("Price")
                        TextField("Price", value: $price, format: .currency(code: "USD"))
                    }
                }
            }
            .navigationTitle("New Portfolio")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let portfolio = Portfolio(name: name.isEmpty ? "Portfolio" : name)
                        if !symbol.isEmpty {
                            let holding = Holding(symbol: symbol, quantity: quantity, costBasis: quantity * price, currentPrice: price, date: Date())
                            portfolio.holdings.append(holding)
                        }
                        modelContext.insert(portfolio)
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

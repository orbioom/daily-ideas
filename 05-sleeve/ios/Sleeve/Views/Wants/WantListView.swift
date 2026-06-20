import SwiftUI
import SwiftData

enum WantFilter: String, CaseIterable {
    case all    = "All"
    case active = "Active"
}

struct WantListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WantCard.priority, order: .reverse) private var allWants: [WantCard]

    @State private var showingAddWant = false
    @State private var wantFilter: WantFilter = .active

    var filteredWants: [WantCard] {
        switch wantFilter {
        case .all:    return allWants
        case .active: return allWants.filter { !$0.isAcquired }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SleeveTheme.darkBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Filter toggle
                    Picker("Filter", selection: $wantFilter) {
                        ForEach(WantFilter.allCases, id: \.self) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    if filteredWants.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "heart")
                                .font(.system(size: 52))
                                .foregroundStyle(SleeveTheme.subtleText)
                            Text(wantFilter == .active ? "Nothing on your want list" : "Want list is empty")
                                .font(.title3)
                                .foregroundStyle(.white)
                            Text("Tap + to add cards you're hunting for")
                                .font(.subheadline)
                                .foregroundStyle(SleeveTheme.subtleText)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredWants) { want in
                                WantRow(want: want)
                                    .listRowBackground(want.isAcquired ? SleeveTheme.cardBg.opacity(0.5) : SleeveTheme.cardBg)
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        Button {
                                            withAnimation { want.isAcquired.toggle() }
                                        } label: {
                                            Label(
                                                want.isAcquired ? "Un-acquire" : "Acquired",
                                                systemImage: want.isAcquired ? "xmark.circle" : "checkmark.circle"
                                            )
                                        }
                                        .tint(.green)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            modelContext.delete(want)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .animation(.easeInOut, value: filteredWants.map(\.isAcquired))
                    }
                }

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showingAddWant = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(Color(red: 0.95, green: 0.35, blue: 0.55))
                                .clipShape(Circle())
                                .shadow(color: Color(red: 0.95, green: 0.35, blue: 0.55).opacity(0.5), radius: 8, y: 4)
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Want List")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("\(filteredWants.count)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(SleeveTheme.subtleText)
                }
            }
        }
        .sheet(isPresented: $showingAddWant) {
            AddWantView()
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Want Row

struct WantRow: View {
    let want: WantCard

    var body: some View {
        HStack(spacing: 12) {
            Text(want.priorityIcon)
                .font(.title3)

            VStack(alignment: .leading, spacing: 3) {
                Text(want.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(want.isAcquired ? SleeveTheme.subtleText : .white)
                    .strikethrough(want.isAcquired, color: SleeveTheme.subtleText)

                HStack(spacing: 6) {
                    if !want.setName.isEmpty {
                        Text(want.setName)
                            .font(.caption)
                            .foregroundStyle(SleeveTheme.subtleText)
                    }
                    Text(want.game)
                        .font(.caption)
                        .foregroundStyle(SleeveTheme.subtleText)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                if want.maxPrice > 0 {
                    Text("≤ $\(want.maxPrice, specifier: "%.2f")")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(want.isAcquired ? SleeveTheme.subtleText : SleeveTheme.gold)
                }
                if want.isAcquired {
                    Text("Acquired")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Want View

struct AddWantView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var setName = ""
    @State private var game: CardGame = .pokemon
    @State private var rarity: CardRarity = .rare
    @State private var maxPrice = ""
    @State private var priority = 2
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ZStack {
                SleeveTheme.darkBg.ignoresSafeArea()

                Form {
                    Section {
                        TextField("Card Name", text: $name)
                            .foregroundStyle(.white)
                        TextField("Set Name (optional)", text: $setName)
                            .foregroundStyle(.white)
                    } header: {
                        Text("Card Info").sleeveSectionHeader()
                    }
                    .listRowBackground(SleeveTheme.cardBg)

                    Section {
                        Picker("Game", selection: $game) {
                            ForEach(CardGame.allCases) { g in
                                Text(g.rawValue).tag(g)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundStyle(.white)

                        Picker("Rarity", selection: $rarity) {
                            ForEach(CardRarity.allCases) { r in
                                Text(r.rawValue).tag(r)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundStyle(.white)
                    } header: {
                        Text("Details").sleeveSectionHeader()
                    }
                    .listRowBackground(SleeveTheme.cardBg)

                    Section {
                        HStack {
                            Text("Max Price")
                                .foregroundStyle(.white)
                            Spacer()
                            Text("$")
                                .foregroundStyle(SleeveTheme.subtleText)
                            TextField("0.00", text: $maxPrice)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.white)
                                .frame(width: 80)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Priority")
                                .foregroundStyle(.white)
                            HStack(spacing: 12) {
                                ForEach([1, 2, 3], id: \.self) { p in
                                    Button {
                                        priority = p
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(priorityIcon(p))
                                            Text(priorityLabel(p))
                                                .font(.caption)
                                                .fontWeight(priority == p ? .bold : .regular)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(priority == p ? SleeveTheme.accent.opacity(0.3) : SleeveTheme.darkBg)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(priority == p ? SleeveTheme.accent : Color.clear, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(.white)
                                }
                            }
                        }
                    } header: {
                        Text("Targeting").sleeveSectionHeader()
                    }
                    .listRowBackground(SleeveTheme.cardBg)

                    Section {
                        TextEditor(text: $notes)
                            .foregroundStyle(.white)
                            .frame(minHeight: 60)
                            .scrollContentBackground(.hidden)
                    } header: {
                        Text("Notes").sleeveSectionHeader()
                    }
                    .listRowBackground(SleeveTheme.cardBg)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add to Wants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(SleeveTheme.silver)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveWant()
                    }
                    .foregroundStyle(name.isEmpty ? SleeveTheme.subtleText : SleeveTheme.accent)
                    .disabled(name.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func priorityIcon(_ p: Int) -> String {
        switch p {
        case 3: return "🔴"
        case 2: return "🟡"
        default: return "🟢"
        }
    }

    private func priorityLabel(_ p: Int) -> String {
        switch p {
        case 3: return "High"
        case 2: return "Med"
        default: return "Low"
        }
    }

    private func saveWant() {
        let want = WantCard(
            name: name,
            setName: setName,
            game: game.rawValue,
            rarity: rarity.rawValue,
            maxPrice: Double(maxPrice) ?? 0.0,
            priority: priority,
            notes: notes
        )
        modelContext.insert(want)
        dismiss()
    }
}

#Preview {
    WantListView()
}

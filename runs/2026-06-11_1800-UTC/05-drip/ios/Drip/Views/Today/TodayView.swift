import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(sort: \DrinkEntry.date, order: .reverse) private var allEntries: [DrinkEntry]
    @Query private var goals: [DrinkGoal]
    @Environment(\.modelContext) private var ctx
    @State private var showAdd = false
    @State private var editEntry: DrinkEntry? = nil

    private var goal: DrinkGoal? { goals.first }
    private var todayEntries: [DrinkEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return allEntries.filter { Calendar.current.startOfDay(for: $0.date) == today }
    }
    private var todayDrinks: Double { todayEntries.reduce(0) { $0 + $1.standardDrinks } }
    private var weekDrinks: Double { DripEngine.weekDrinks(entries: allEntries) }
    private var weekLimit: Int { goal?.weeklyLimit ?? 14 }
    private var weekProgress: Double { min(1, weekDrinks / Double(max(1, weekLimit))) }
    private var afDays: Int { DripEngine.alcoholFreeDaysThisWeek(entries: allEntries) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    weekSummary
                    todaySection
                    quickAdd
                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .background(DripTheme.bg)
            .navigationTitle("Drip")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAdd) {
                AddDrinkView()
            }
            .sheet(item: $editEntry) { entry in
                EditDrinkView(entry: entry)
            }
        }
    }

    @ViewBuilder
    private var weekSummary: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Week")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DripTheme.subtle)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", weekDrinks))
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(DripTheme.statusColor(drinks: weekDrinks, limit: weekLimit))
                        Text("/ \(weekLimit) drinks")
                            .font(.subheadline)
                            .foregroundStyle(DripTheme.subtle)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("AF Days")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DripTheme.subtle)
                    Text("\(afDays)")
                        .font(.title.weight(.bold))
                        .foregroundStyle(afDays >= (goal?.alcoholFreeDaysTarget ?? 0) ? DripTheme.safe : DripTheme.warning)
                }
            }

            ProgressView(value: weekProgress)
                .tint(DripTheme.statusColor(drinks: weekDrinks, limit: weekLimit))
                .scaleEffect(y: 1.5)
                .accessibilityLabel("Weekly progress: \(Int(weekProgress * 100)) percent of limit")
        }
        .padding()
        .background(DripTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today · \(String(format: "%.1f", todayDrinks)) drinks")
                    .font(.headline)
                    .foregroundStyle(DripTheme.text)
                Spacer()
                Button { showAdd = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(DripTheme.accent)
                        .accessibilityLabel("Add drink")
                }
            }

            if todayEntries.isEmpty {
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundStyle(DripTheme.accent.opacity(0.4))
                        .accessibilityHidden(true)
                    Text("Alcohol-free so far today")
                        .font(.subheadline)
                        .foregroundStyle(DripTheme.subtle)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DripTheme.safe.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel("No drinks logged today")
            } else {
                ForEach(todayEntries) { entry in
                    DrinkRowView(entry: entry)
                        .onTapGesture { editEntry = entry }
                }
            }
        }
    }

    @ViewBuilder
    private var quickAdd: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Add")
                .font(.headline)
                .foregroundStyle(DripTheme.text)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(DrinkType.allCases.filter { $0 != .other }, id: \.self) { type in
                    Button {
                        quickLog(type: type)
                    } label: {
                        VStack(spacing: 6) {
                            Text(type.emoji).font(.title2).accessibilityHidden(true)
                            Text(type.rawValue).font(.caption.weight(.medium)).foregroundStyle(DripTheme.text)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(DripTheme.card, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Quick add \(type.rawValue)")
                    .accessibilityHint("Log a standard \(type.rawValue)")
                }
            }
        }
    }

    private func quickLog(type: DrinkType) {
        let entry = DrinkEntry(
            drinkType: type,
            abv: type.defaultABV,
            volumeML: type.defaultVolumeML
        )
        ctx.insert(entry)
    }
}

struct DrinkRowView: View {
    let entry: DrinkEntry
    @Environment(\.modelContext) private var ctx

    var body: some View {
        HStack(spacing: 12) {
            Text(entry.drinkType.emoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(DripTheme.card, in: RoundedRectangle(cornerRadius: 10))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DripTheme.text)
                Text("\(String(format: "%.1f", entry.standardDrinks)) std · \(Int(entry.abv))% ABV · \(Int(entry.volumeML))mL")
                    .font(.caption)
                    .foregroundStyle(DripTheme.subtle)
            }

            Spacer()

            Text(entry.date.formatted(.dateTime.hour().minute()))
                .font(.caption)
                .foregroundStyle(DripTheme.subtle)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(DripTheme.card, in: RoundedRectangle(cornerRadius: 12))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { ctx.delete(entry) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.name), \(String(format: "%.1f", entry.standardDrinks)) standard drinks at \(entry.date.formatted(.dateTime.hour().minute()))")
    }
}

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \EmissionEntry.date, order: .reverse) private var allEntries: [EmissionEntry]
    @Environment(\.modelContext) private var modelContext

    @State private var selectedCategory: EmissionCategory? = nil
    @State private var editingEntry: EmissionEntry? = nil

    private var filteredEntries: [EmissionEntry] {
        guard let cat = selectedCategory else { return allEntries }
        return allEntries.filter { $0.category == cat }
    }

    private var groupedByWeek: [(weekLabel: String, weekTotal: Double, entries: [EmissionEntry])] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        let grouped = Dictionary(grouping: filteredEntries) { entry -> Date in
            var comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: entry.date)
            comps.weekday = 2 // Monday
            return calendar.date(from: comps) ?? entry.date
        }

        return grouped
            .map { (date, entries) -> (weekLabel: String, weekTotal: Double, entries: [EmissionEntry]) in
                let endDate = calendar.date(byAdding: .day, value: 6, to: date) ?? date
                let label = "\(formatter.string(from: date)) – \(formatter.string(from: endDate))"
                let total = entries.reduce(0) { $0 + $1.co2eKg }
                return (label, total, entries.sorted { $0.date > $1.date })
            }
            .sorted { lhs, rhs in
                let lhsDate = lhs.entries.first?.date ?? Date.distantPast
                let rhsDate = rhs.entries.first?.date ?? Date.distantPast
                return lhsDate > rhsDate
            }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar

                if filteredEntries.isEmpty {
                    EmptyStateView(
                        systemImage: "clock.fill",
                        title: selectedCategory == nil ? "No entries yet" : "No \(selectedCategory?.rawValue ?? "") entries",
                        subtitle: selectedCategory == nil
                            ? "Your logged emissions will appear here."
                            : "Try logging a \(selectedCategory?.rawValue.lowercased() ?? "") activity."
                    )
                } else {
                    List {
                        ForEach(groupedByWeek, id: \.weekLabel) { group in
                            Section {
                                ForEach(group.entries) { entry in
                                    entryRow(entry)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                deleteEntry(entry)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                        .onTapGesture {
                                            editingEntry = entry
                                        }
                                }
                            } header: {
                                weekSectionHeader(group.weekLabel, total: group.weekTotal)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $editingEntry) { entry in
                LogEntryView(editingEntry: entry)
            }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                filterChip(label: "All", category: nil)
                ForEach(EmissionCategory.allCases, id: \.self) { cat in
                    filterChip(label: cat.rawValue, category: cat)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private func filterChip(label: String, category: EmissionCategory?) -> some View {
        let isSelected = selectedCategory == category
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = category
            }
        } label: {
            HStack(spacing: 4) {
                if let cat = category {
                    Image(systemName: cat.icon)
                        .font(.caption)
                }
                Text(label)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? (category?.swiftUIColor ?? .canopyGreen)
                    : Color(.secondarySystemBackground),
                in: Capsule()
            )
        }
        .accessibilityLabel("Filter by \(label)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Week Header

    private func weekSectionHeader(_ label: String, total: Double) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
            Text(String(format: "%.1f kg", total))
                .font(.subheadline)
                .foregroundStyle(.canopyGreen)
                .fontWeight(.semibold)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Week of \(label), total \(String(format: "%.1f", total)) kg CO2e")
    }

    // MARK: - Entry Row

    private func entryRow(_ entry: EmissionEntry) -> some View {
        HStack(spacing: 12) {
            CategoryIcon(category: entry.category, size: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.activityName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    Text("\(String(format: "%g", entry.amount)) \(entry.activityUnit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !entry.notes.isEmpty {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(entry.notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            Co2Badge(kg: entry.co2eKg, compact: true)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityLabel("\(entry.activityName), \(String(format: "%g", entry.amount)) \(entry.activityUnit), \(String(format: "%.2f", entry.co2eKg)) kg CO2e")
        .accessibilityHint("Tap to edit. Swipe left to delete.")
    }

    // MARK: - Actions

    private func deleteEntry(_ entry: EmissionEntry) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        modelContext.delete(entry)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [EmissionEntry.self, CanopySettings.self], inMemory: true)
}

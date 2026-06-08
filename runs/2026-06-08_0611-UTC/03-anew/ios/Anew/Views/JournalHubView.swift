import SwiftUI
import SwiftData

/// Cross-quit journal view: all check-ins sorted most-recent-first.
struct JournalHubView: View {
    @Query(sort: \CheckIn.date, order: .reverse) private var checkIns: [CheckIn]
    @Query(sort: \Quit.order) private var allQuits: [Quit]
    @AppStorage("anew.showInactive") private var showInactive: Bool = false

    @State private var showAddCheckIn = false
    @State private var selectedQuit: Quit? = nil
    @State private var filterQuitID: UUID? = nil

    private var filteredCheckIns: [CheckIn] {
        if let id = filterQuitID {
            return checkIns.filter { $0.quit?.id == id }
        }
        return checkIns
    }

    private var activeQuits: [Quit] {
        showInactive ? allQuits : allQuits.filter(\.active)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                VStack(spacing: 0) {
                    // Filter bar
                    filterBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    if filteredCheckIns.isEmpty {
                        EmptyStateView(
                            icon: "book.closed",
                            title: "No journal entries",
                            message: "Use the + button to log how you're feeling today."
                        )
                        .padding(.horizontal, 16)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(filteredCheckIns) { checkIn in
                                    JournalEntryCard(checkIn: checkIn)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if let first = activeQuits.first {
                            selectedQuit = first
                            showAddCheckIn = true
                        }
                        Haptics.tap()
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Add journal check-in")
                    .disabled(activeQuits.isEmpty)
                }
            }
            .sheet(isPresented: $showAddCheckIn) {
                if let quit = selectedQuit {
                    AddCheckInView(quit: quit)
                }
            }
        }
    }

    @ViewBuilder
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", selected: filterQuitID == nil) {
                    filterQuitID = nil
                    Haptics.selection()
                }
                ForEach(activeQuits) { quit in
                    FilterChip(label: quit.name, selected: filterQuitID == quit.id) {
                        if filterQuitID == quit.id {
                            filterQuitID = nil
                        } else {
                            filterQuitID = quit.id
                            selectedQuit = quit
                        }
                        Haptics.selection()
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Filter chip

private struct FilterChip: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(selected ? .semibold : .regular))
                .foregroundStyle(selected ? Brand.text : Brand.text2)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    selected ? Brand.live.opacity(0.18) : Color.secondary.opacity(0.1),
                    in: Capsule()
                )
                .overlay(Capsule().strokeBorder(selected ? Brand.live : Color.clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

// MARK: - Journal entry card

private struct JournalEntryCard: View {
    let checkIn: CheckIn

    var body: some View {
        GlassCard(padding: 14) {
            HStack(alignment: .top, spacing: 14) {
                Text(Format.moodEmoji(checkIn.mood))
                    .font(.title)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(Format.moodLabel(checkIn.mood))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Brand.text)

                        if let qName = checkIn.quit?.name {
                            Text("· \(qName)")
                                .font(.caption)
                                .foregroundStyle(Brand.text3)
                        }

                        Spacer()

                        if checkIn.pledged {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Brand.live)
                                .font(.caption)
                                .accessibilityLabel("Pledged")
                        }
                    }

                    if !checkIn.note.isEmpty {
                        Text(checkIn.note)
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                            .lineLimit(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text(Format.shortDate(checkIn.date))
                        .font(.caption2)
                        .foregroundStyle(Brand.text3)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Format.shortDate(checkIn.date)), \(checkIn.quit?.name ?? ""), \(Format.moodLabel(checkIn.mood))\(checkIn.note.isEmpty ? "" : ": \(checkIn.note)")")
    }
}

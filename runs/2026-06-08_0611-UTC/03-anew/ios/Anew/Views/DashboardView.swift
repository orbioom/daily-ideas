import SwiftUI
import SwiftData

struct DashboardView: View {
    @AppStorage("anew.currency")     private var currencySymbol: String = "$"
    @AppStorage("anew.showInactive") private var showInactive: Bool = false

    @Query(sort: \Quit.order) private var allQuits: [Quit]
    @Environment(\.modelContext) private var modelContext

    @State private var showAddQuit = false

    private var quits: [Quit] {
        showInactive ? allQuits : allQuits.filter(\.active)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                if quits.isEmpty {
                    EmptyStateView(
                        icon: "plus.circle",
                        title: "Nothing tracked yet",
                        message: "Tap + to add your first quit and start your streak."
                    )
                    .padding(.horizontal, 16)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(quits) { quit in
                                NavigationLink(value: quit) {
                                    QuitCardView(quit: quit, currencySymbol: currencySymbol)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Anew")
            .navigationDestination(for: Quit.self) { quit in
                QuitDetailView(quit: quit)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddQuit = true
                        Haptics.tap()
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Add new quit")
                }
            }
            .sheet(isPresented: $showAddQuit) {
                AddEditQuitView(quit: nil)
            }
        }
    }
}

// MARK: - Quit card

struct QuitCardView: View {
    let quit: Quit
    let currencySymbol: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header row
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: quit.colorHex).opacity(0.2))
                            .frame(width: 40, height: 40)
                        Image(systemName: quit.symbol)
                            .font(.system(size: 18))
                            .foregroundStyle(Color(hex: quit.colorHex))
                    }
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(quit.name)
                            .font(.headline)
                            .foregroundStyle(Brand.text)

                        Text(quit.category.displayName)
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                    }

                    Spacer()

                    StatusDot(color: quit.active ? Brand.live : Brand.text3)
                }

                // Live counter
                LiveCounterView(startDate: quit.startDate)

                // Stats row
                HStack(spacing: 0) {
                    StatCell(
                        label: "saved",
                        value: Format.currency(SobrietyEngine.moneySaved(quit: quit, now: Date()), symbol: currencySymbol)
                    )

                    Divider()
                        .frame(height: 28)
                        .padding(.horizontal, 12)

                    StatCell(
                        label: quit.unitLabel,
                        value: String(format: "%.1f", SobrietyEngine.unitsAvoided(quit: quit, now: Date()))
                    )

                    Spacer()

                    // Next milestone ring
                    if let next = SobrietyEngine.nextMilestone(quit: quit, now: Date()) {
                        HStack(spacing: 8) {
                            VStack(alignment: .trailing, spacing: 1) {
                                Text("Next")
                                    .font(.caption2)
                                    .foregroundStyle(Brand.text3)
                                Text(next.milestone.title)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Brand.text2)
                                    .lineLimit(1)
                            }
                            RingProgress(
                                progress: next.progress,
                                size: 36,
                                lineWidth: 3,
                                color: Color(hex: quit.colorHex)
                            )
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(quit.name), \(SobrietyEngine.cleanDays(start: quit.startDate, now: Date())) days clean")
        .accessibilityHint("Tap to view details")
    }
}

// MARK: - Stat cell

private struct StatCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(Brand.mono(15, weight: .semibold))
                .foregroundStyle(Brand.text)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Brand.text3)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

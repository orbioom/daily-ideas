import SwiftUI

/// Sheet for starting a new game: random, today's, or (Pro) a specific deal number.
struct NewGameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("isPro") private var isPro = false

    let isGameInProgress: Bool
    let confirmBeforeAbandon: Bool
    let onStart: (Int) -> Void

    @State private var dealNumberText: String = ""
    @State private var pendingDeal: Int?
    @State private var showAbandonConfirm = false
    @State private var showPaywall = false

    private var todaysDeal: Int { FreeCellEngine.dealNumber(for: .now) }

    /// Parsed, validated deal number from the text field (1...1_000_000), or nil.
    private var parsedDeal: Int? {
        guard let n = Int(dealNumberText.trimmingCharacters(in: .whitespaces)) else { return nil }
        return (1...1_000_000).contains(n) ? n : nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    optionRow(
                        title: "Random deal",
                        subtitle: "A fresh, solvable shuffle",
                        symbol: "shuffle"
                    ) {
                        attemptStart(FreeCellEngine.randomDealNumber())
                    }

                    optionRow(
                        title: "Today's deal",
                        subtitle: "Deal #\(todaysDeal) · everyone plays the same one",
                        symbol: "calendar"
                    ) {
                        attemptStart(todaysDeal)
                    }
                } header: {
                    Text("Quick start")
                }

                Section {
                    if isPro {
                        HStack {
                            Image(systemName: "number")
                                .foregroundStyle(Theme.accent)
                                .accessibilityHidden(true)
                            TextField("Deal number (1–1,000,000)", text: $dealNumberText)
                                .keyboardType(.numberPad)
                                .accessibilityLabel("Deal number")
                        }
                        Button {
                            if let deal = parsedDeal { attemptStart(deal) }
                        } label: {
                            Text("Play this deal")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(parsedDeal == nil)
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.accent)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        if !dealNumberText.isEmpty && parsedDeal == nil {
                            Text("Enter a number from 1 to 1,000,000.")
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(Theme.gold)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Choose a specific deal")
                                        .font(.body)
                                    Text("Unlock with Citadel Pro")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .accessibilityHidden(true)
                            }
                        }
                        .accessibilityHint("Opens the Citadel Pro upgrade")
                    }
                } header: {
                    Text("Pick a deal")
                } footer: {
                    Text("Numbered deals match the classic FreeCell catalog — share a number and a friend plays the exact same board.")
                }
            }
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .confirmationDialog(
                "Abandon the current game?",
                isPresented: $showAbandonConfirm,
                titleVisibility: .visible
            ) {
                Button("Start new game", role: .destructive) {
                    if let deal = pendingDeal {
                        onStart(deal)
                        dismiss()
                    }
                }
                Button("Keep playing", role: .cancel) { pendingDeal = nil }
            } message: {
                Text("Your current game will be recorded as a loss in your stats.")
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    @ViewBuilder
    private func optionRow(title: String, subtitle: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 28)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func attemptStart(_ deal: Int) {
        if isGameInProgress && confirmBeforeAbandon {
            pendingDeal = deal
            showAbandonConfirm = true
        } else {
            onStart(deal)
            dismiss()
        }
    }
}

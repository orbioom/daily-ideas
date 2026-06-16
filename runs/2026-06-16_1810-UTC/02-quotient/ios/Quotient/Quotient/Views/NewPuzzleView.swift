import SwiftUI

/// Lets the player pick a difficulty (and thus grid size). Pro tiers (6×6/7×7)
/// are gated behind the paywall for free users.
struct NewPuzzleView: View {
    let onGenerate: (Difficulty) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage("isPro") private var isPro = false
    @State private var selected: Difficulty = .easy
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Text("Choose a puzzle")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Bigger grids are tougher. Fill each row and column with the numbers once and satisfy every cage.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(Difficulty.allCases) { difficulty in
                        difficultyRow(difficulty)
                    }

                    Button {
                        if selected.requiresPro && !isPro {
                            showingPaywall = true
                        } else {
                            onGenerate(selected)
                        }
                    } label: {
                        Label("Generate Puzzle", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("New Puzzle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    private func difficultyRow(_ difficulty: Difficulty) -> some View {
        let locked = difficulty.requiresPro && !isPro
        let isSelected = selected == difficulty
        return Button {
            selected = difficulty
        } label: {
            HStack(spacing: 14) {
                Image(systemName: difficulty.systemImage)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : Theme.accent)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle().fill(isSelected ? Theme.accent : Theme.accent.opacity(0.12))
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(difficulty.displayName)
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        if locked { ProBadge() }
                    }
                    Text(difficulty.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: locked ? "lock.fill" : (isSelected ? "checkmark.circle.fill" : "circle"))
                    .foregroundStyle(locked ? Theme.textSecondary : (isSelected ? Theme.accent : Theme.textSecondary))
                    .accessibilityHidden(true)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Theme.accent : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(difficulty.displayName), \(difficulty.subtitle)\(locked ? ", Pro feature, locked" : "")")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
        .accessibilityHint(locked ? "Requires Quotient Pro" : "Select this difficulty")
    }
}

import SwiftUI

/// Small pill tag used on recipe cards.
struct TagPill: View {
    let text: String
    var tint: Color = Theme.terracotta

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(tint.opacity(0.14), in: Capsule())
            .foregroundStyle(tint)
    }
}

/// Meta line "20 min · Easy · 4 servings".
struct RecipeMeta: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 6) {
            Label("\(recipe.totalMinutes) min", systemImage: "clock")
            Text("·")
            Text(recipe.effort.rawValue)
            Text("·")
            Label("\(recipe.servings)", systemImage: "person.2")
        }
        .font(.caption)
        .foregroundStyle(Theme.secondaryText)
        .labelStyle(.titleAndIcon)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recipe.totalMinutes) minutes, \(recipe.effort.rawValue) effort, serves \(recipe.servings)")
    }
}

/// Stepper-style servings control reused in sheets.
struct ServingsStepper: View {
    @Binding var servings: Int
    var range: ClosedRange<Int> = 1...20

    var body: some View {
        HStack(spacing: 16) {
            Button {
                if servings > range.lowerBound { servings -= 1; Haptics.selection() }
            } label: {
                Image(systemName: "minus.circle.fill")
            }
            .disabled(servings <= range.lowerBound)
            .accessibilityLabel("Decrease servings")

            Text("\(servings)")
                .font(.title3.weight(.semibold).monospacedDigit())
                .frame(minWidth: 42)
                .foregroundStyle(Theme.primaryText)
                .accessibilityLabel("\(servings) servings")

            Button {
                if servings < range.upperBound { servings += 1; Haptics.selection() }
            } label: {
                Image(systemName: "plus.circle.fill")
            }
            .disabled(servings >= range.upperBound)
            .accessibilityLabel("Increase servings")
        }
        .font(.title2)
        .foregroundStyle(Theme.terracotta)
    }
}

/// A header for a section card.
struct SectionHeader: View {
    let title: String
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(Theme.terracotta)
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.primaryText)
            Spacer()
        }
    }
}

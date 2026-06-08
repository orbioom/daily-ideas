import SwiftUI

/// Full-screen, distraction-free step-by-step cooking. Stays awake-friendly and
/// shows scaled ingredients alongside the current step.
struct CookModeView: View {
    let recipe: Recipe
    let servings: Int
    @Environment(\.dismiss) private var dismiss
    @State private var index = 0

    private let engine = MealEngine()
    private var steps: [Step] { recipe.steps.sorted { $0.order < $1.order } }
    private var factor: Double { engine.factor(base: recipe.servings, target: servings) }

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                header
                if steps.isEmpty {
                    Spacer()
                    EmptyStateView(icon: "list.number", title: "No steps",
                                   message: "This recipe has no method to cook through yet.")
                    Spacer()
                } else {
                    TabView(selection: $index) {
                        ForEach(Array(steps.enumerated()), id: \.element.id) { i, step in
                            stepPage(i, step).tag(i)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    controls
                }
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.name).font(.headline).foregroundStyle(Brand.text).lineLimit(1)
                Text("\(servings) servings").font(.caption).foregroundStyle(Brand.text3)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill").font(.title2).foregroundStyle(Brand.text3)
            }
            .accessibilityLabel("Close cook mode")
        }
        .padding()
    }

    private func stepPage(_ i: Int, _ step: Step) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Step \(i + 1) of \(steps.count)")
                    .font(Brand.mono(13, weight: .medium)).foregroundStyle(Color.accentColor)
                Text(step.text)
                    .font(.title2.weight(.medium))
                    .foregroundStyle(Brand.text)
                    .fixedSize(horizontal: false, vertical: true)

                if !recipe.ingredients.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow(text: "Ingredients")
                        ForEach(recipe.ingredients.sorted { $0.order < $1.order }) { ing in
                            HStack(spacing: 8) {
                                Text(Quantity.withUnit(engine.scaled(ing, factor: factor), unit: ing.unit))
                                    .font(Brand.mono(12, weight: .medium)).foregroundStyle(Color.accentColor)
                                    .frame(width: 80, alignment: .leading)
                                Text(ing.name).font(.subheadline).foregroundStyle(Brand.text2)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var controls: some View {
        HStack(spacing: 14) {
            Button {
                withAnimation(Brand.ease(0.3)) { index = max(0, index - 1) }
                Haptics.tap()
            } label: { Label("Back", systemImage: "chevron.left") }
                .buttonStyle(GlassButtonStyle())
                .disabled(index == 0)

            if index == steps.count - 1 {
                Button {
                    Haptics.success(); dismiss()
                } label: { Label("Done", systemImage: "checkmark") }
                    .buttonStyle(InkButtonStyle())
            } else {
                Button {
                    withAnimation(Brand.ease(0.3)) { index = min(steps.count - 1, index + 1) }
                    Haptics.tap()
                } label: { Label("Next", systemImage: "chevron.right") }
                    .buttonStyle(InkButtonStyle())
            }
        }
        .padding()
    }
}

import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @Bindable var recipe: Recipe
    @Environment(\.modelContext) private var context

    @State private var targetServings: Int
    @State private var editing = false
    @State private var cooking = false

    private let engine = MealEngine()

    init(recipe: Recipe) {
        self.recipe = recipe
        _targetServings = State(initialValue: recipe.servings)
    }

    private var factor: Double { engine.factor(base: recipe.servings, target: targetServings) }

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(spacing: 16) {
                    header
                    servingScaler
                    ingredientsCard
                    stepsCard
                    if !recipe.notes.isEmpty { notesCard }
                    if recipe.totalMinutes > 0 || !recipe.steps.isEmpty { cookButton }
                }
                .padding()
            }
        }
        .navigationTitle(recipe.name.isEmpty ? "Recipe" : recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button {
                        recipe.favorite.toggle(); Haptics.selection()
                    } label: {
                        Image(systemName: recipe.favorite ? "heart.fill" : "heart")
                            .foregroundStyle(recipe.favorite ? Color(hex: 0xC0553E) : Brand.text2)
                    }
                    .accessibilityLabel(recipe.favorite ? "Unfavorite" : "Favorite")
                    Button { editing = true } label: { Image(systemName: "pencil") }
                        .accessibilityLabel("Edit recipe")
                }
            }
        }
        .sheet(isPresented: $editing) { RecipeEditorView(recipe: recipe, isNew: false) }
        .fullScreenCover(isPresented: $cooking) {
            CookModeView(recipe: recipe, servings: targetServings)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !recipe.summary.isEmpty {
                Text(recipe.summary).font(.subheadline).foregroundStyle(Brand.text2)
            }
            HStack(spacing: 18) {
                meta("\(recipe.prepMinutes)m", "prep", "scissors")
                meta("\(recipe.cookMinutes)m", "cook", "flame.fill")
                meta("\(recipe.totalMinutes)m", "total", "clock.fill")
                meta(recipe.course.label, "course", recipe.course.symbol)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func meta(_ value: String, _ label: String, _ symbol: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: symbol).font(.caption).foregroundStyle(Color.accentColor)
            Text(value).font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(.caption2).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine).accessibilityLabel("\(value) \(label)")
    }

    private var servingScaler: some View {
        HStack {
            Text("Servings").font(.headline).foregroundStyle(Brand.text)
            Spacer()
            Stepper(value: $targetServings, in: 1...50) {
                Text("\(targetServings)")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.accentColor)
                    .contentTransition(.numericText())
            }
            .labelsHidden()
            .fixedSize()
            Text("\(targetServings)")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 36)
                .accessibilityHidden(true)
        }
        .glassCard()
    }

    private var ingredientsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ingredients").font(.headline).foregroundStyle(Brand.text)
            if recipe.ingredients.isEmpty {
                Text("No ingredients yet. Tap edit to add some.")
                    .font(.subheadline).foregroundStyle(Brand.text3)
            } else {
                ForEach(recipe.ingredients.sorted { $0.order < $1.order }) { ing in
                    HStack(alignment: .top, spacing: 10) {
                        Text(Quantity.withUnit(engine.scaled(ing, factor: factor), unit: ing.unit))
                            .font(Brand.mono(13, weight: .medium))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 86, alignment: .leading)
                        Text(ing.name).font(.subheadline).foregroundStyle(Brand.text)
                        Spacer(minLength: 0)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(Quantity.withUnit(engine.scaled(ing, factor: factor), unit: ing.unit)) \(ing.name)")
                }
            }
        }
        .glassCard()
    }

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Method").font(.headline).foregroundStyle(Brand.text)
            if recipe.steps.isEmpty {
                Text("No steps yet. Tap edit to add the method.")
                    .font(.subheadline).foregroundStyle(Brand.text3)
            } else {
                ForEach(Array(recipe.steps.sorted { $0.order < $1.order }.enumerated()), id: \.element.id) { idx, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(idx + 1)")
                            .font(Brand.mono(13, weight: .bold)).foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.accentColor))
                        Text(step.text).font(.subheadline).foregroundStyle(Brand.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .glassCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Eyebrow(text: "Notes")
            Text(recipe.notes).font(.subheadline).foregroundStyle(Brand.text2)
        }
        .glassCard()
    }

    private var cookButton: some View {
        Button {
            Haptics.tap(); cooking = true
        } label: { Label("Cook mode", systemImage: "flame.fill") }
            .buttonStyle(InkButtonStyle())
            .disabled(recipe.steps.isEmpty)
    }
}

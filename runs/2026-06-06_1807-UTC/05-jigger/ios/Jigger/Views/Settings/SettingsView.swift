import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var ingredients: [Ingredient]
    @Query private var recipes: [Recipe]

    @AppStorage("hideOutOfStock") private var hideOutOfStock = false
    @AppStorage("defaultMeasure") private var defaultMeasureRaw = Measure.oz.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("didSeed") private var didSeed = false

    @State private var confirmDelete = false
    @State private var confirmReseed = false
    @State private var confirmEmptyBar = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Picker("Default measure", selection: $defaultMeasureRaw) {
                        ForEach([Measure.oz, .ml]) { Text($0.rawValue).tag($0.rawValue) }
                    }
                    Toggle("Hide out-of-stock in Bar", isOn: $hideOutOfStock)
                    Toggle("Haptics", isOn: $hapticsEnabled)
                }
                Section("Quick actions") {
                    Button {
                        confirmEmptyBar = true
                    } label: { Label("Mark everything out of stock", systemImage: "xmark.circle") }
                }
                Section("Library") {
                    LabeledContent("Ingredients", value: "\(ingredients.count)")
                    LabeledContent("Recipes", value: "\(recipes.count)")
                    Button { confirmReseed = true } label: { Label("Reload sample bar", systemImage: "arrow.clockwise") }
                    Button(role: .destructive) { confirmDelete = true } label: { Label("Delete all data", systemImage: "trash") }
                }
                Section {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Design", value: "Orbioom")
                } header: { Text("About") } footer: {
                    Text("Jigger runs entirely on your device. Makeability ignores optional lines (garnishes, \"to taste\"); shopping suggestions rank bottles by how many recipes each would unlock on its own.")
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle("Settings")
            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
            .alert("Mark everything out of stock?", isPresented: $confirmEmptyBar) {
                Button("Mark all out", role: .destructive) { emptyBar() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Useful when you move or restock. Toggle bottles back in the Bar tab.") }
            .alert("Delete all data?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) { deleteAll() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Removes every ingredient and recipe. This can't be undone.") }
            .alert("Reload sample bar?", isPresented: $confirmReseed) {
                Button("Reload", role: .destructive) { reseed() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Clears current data and restores the demo bar and classics.") }
        }
    }

    private func emptyBar() {
        for ing in ingredients { ing.inStock = false }
        try? context.save(); Haptics.warning()
    }
    private func deleteAll() {
        for r in recipes { context.delete(r) }
        for ing in ingredients { context.delete(ing) }
        try? context.save(); Haptics.warning()
    }
    private func reseed() { deleteAll(); SampleData.seed(into: context); didSeed = true; Haptics.success() }
}

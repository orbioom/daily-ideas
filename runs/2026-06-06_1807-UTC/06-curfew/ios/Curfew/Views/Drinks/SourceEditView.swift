import SwiftUI
import SwiftData

struct SourceEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let source: CaffeineSource?

    @State private var name = ""
    @State private var mgText = ""
    @State private var category = DrinkCategory.coffee
    @State private var serving = ""
    @State private var favorite = false
    @State private var confirmDelete = false

    private var mg: Double { Double(mgText) ?? 0 }
    private var valid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && mg > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Drink") {
                    TextField("Name (e.g. Cold Brew)", text: $name)
                    HStack {
                        Text("Caffeine")
                        Spacer()
                        TextField("0", text: $mgText).keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing).font(Brand.mono(16)).frame(width: 80)
                        Text("mg").foregroundStyle(Brand.text3)
                    }
                    Picker("Category", selection: $category) {
                        ForEach(DrinkCategory.allCases) { Label($0.rawValue, systemImage: $0.icon).tag($0) }
                    }
                    TextField("Serving (e.g. 12 oz can)", text: $serving)
                    Toggle("Favorite (quick add)", isOn: $favorite)
                }
                if source != nil {
                    Section {
                        Button(role: .destructive) { confirmDelete = true } label: {
                            Label("Delete drink", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle(source == nil ? "New Drink" : "Edit Drink")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!valid) }
            }
            .onAppear(perform: load)
            .alert("Delete this drink?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) {
                    if let s = source { context.delete(s); try? context.save(); Haptics.warning() }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Past intakes that used it are kept.") }
        }
    }

    private func load() {
        guard let s = source else { return }
        name = s.name; mgText = String(Int(s.mg)); category = s.category
        serving = s.serving; favorite = s.favorite
    }
    private func save() {
        if let s = source {
            s.name = name; s.mg = mg; s.category = category; s.serving = serving; s.favorite = favorite
        } else {
            context.insert(CaffeineSource(name: name, mg: mg, category: category, serving: serving, favorite: favorite))
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}

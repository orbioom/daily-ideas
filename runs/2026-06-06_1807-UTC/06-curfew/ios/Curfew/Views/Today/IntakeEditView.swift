import SwiftUI
import SwiftData

struct IntakeEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CaffeineSource.name) private var sources: [CaffeineSource]
    let intake: Intake?

    @State private var name = ""
    @State private var mgText = ""
    @State private var time = Date.now
    @State private var category = DrinkCategory.coffee
    @State private var confirmDelete = false

    private var mg: Double { Double(mgText) ?? 0 }
    private var valid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && mg > 0 }

    var body: some View {
        NavigationStack {
            Form {
                if intake == nil && !sources.isEmpty {
                    Section("Pick a drink") {
                        Menu {
                            ForEach(sources) { s in
                                Button("\(s.name) · \(Int(s.mg)) mg") {
                                    name = s.name; mgText = String(Int(s.mg)); category = s.category
                                }
                            }
                        } label: {
                            Label("Choose from your drinks", systemImage: "cup.and.saucer")
                        }
                    }
                }
                Section("Intake") {
                    TextField("Name (e.g. Drip Coffee)", text: $name)
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
                    DatePicker("Time", selection: $time)
                }
                if intake != nil {
                    Section {
                        Button(role: .destructive) { confirmDelete = true } label: {
                            Label("Delete intake", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle(intake == nil ? "Log Intake" : "Edit Intake")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!valid) }
            }
            .onAppear(perform: load)
            .alert("Delete this intake?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) {
                    if let i = intake { context.delete(i); try? context.save(); Haptics.warning() }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func load() {
        guard let i = intake else { return }
        name = i.name; mgText = String(Int(i.mg)); time = i.time; category = i.category
    }
    private func save() {
        if let i = intake {
            i.name = name; i.mg = mg; i.time = time; i.category = category
        } else {
            context.insert(Intake(name: name, mg: mg, time: time, category: category))
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}

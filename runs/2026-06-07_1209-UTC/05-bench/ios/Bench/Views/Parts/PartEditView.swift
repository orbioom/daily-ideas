import SwiftUI
import SwiftData

struct PartEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var part: Component?

    @State private var name = ""
    @State private var kind: ComponentKind = .resistor
    @State private var value = ""
    @State private var package = ""
    @State private var quantity = 0

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "Part")
                        TextField("Name (e.g. NE555)", text: $name).textFieldStyle(.roundedBorder)
                        HStack {
                            Text("Kind").foregroundStyle(Brand.text)
                            Spacer()
                            Picker("Kind", selection: $kind) {
                                ForEach(ComponentKind.allCases) { Label($0.rawValue, systemImage: $0.symbol).tag($0) }
                            }.pickerStyle(.menu).tint(Brand.text2)
                        }
                        TextField("Value (e.g. 10 kΩ, 100 nF)", text: $value).textFieldStyle(.roundedBorder)
                        TextField("Package (e.g. DIP-8, 0805)", text: $package).textFieldStyle(.roundedBorder)
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "Stock")
                        Stepper("Quantity: \(quantity)", value: $quantity, in: 0...100000)
                            .foregroundStyle(Brand.text)
                        HStack {
                            Text("Quick set").foregroundStyle(Brand.text2).font(.subheadline)
                            Spacer()
                            ForEach([0,10,50,100], id: \.self) { n in
                                Button("\(n)") { quantity = n }
                                    .font(Brand.mono(13, weight: .medium))
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(Brand.glassStroke.opacity(0.18), in: Capsule())
                                    .tint(Brand.text)
                            }
                        }
                    }.glassCard()
                }
                .padding()
            }
            .navigationTitle(part == nil ? "New part" : "Edit part")
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.tint(Brand.text2) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.tint(Brand.text).disabled(trimmed.isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let part else { return }
        name = part.name; kind = part.kind; value = part.value
        package = part.package; quantity = part.quantity
    }

    private func save() {
        let target = part ?? Component(name: trimmed)
        target.name = trimmed
        target.kind = kind
        target.value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        target.package = package.trimmingCharacters(in: .whitespacesAndNewlines)
        target.quantity = max(0, quantity)
        if part == nil { context.insert(target) }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

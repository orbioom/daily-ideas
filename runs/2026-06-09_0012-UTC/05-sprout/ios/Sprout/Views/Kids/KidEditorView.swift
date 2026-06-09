import SwiftUI
import SwiftData

struct KidEditorView: View {
    var kid: Kid?
    var nextIndex: Int

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("sprout.symbol") private var symbol = "$"

    @State private var name = ""
    @State private var color: KidColor = .teal
    @State private var glyph = "face.smiling.fill"
    @State private var allowanceText = ""
    @State private var loaded = false

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Child") {
                    TextField("Name", text: $name)
                }
                Section("Weekly allowance (optional)") {
                    HStack {
                        Text(symbol).foregroundStyle(Brand.text3)
                        TextField("0", text: $allowanceText).keyboardType(.decimalPad)
                    }
                    Text("Sprout adds this automatically each week.")
                        .font(.caption).foregroundStyle(Brand.text3)
                }
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(KidColor.allCases) { c in
                            Circle().fill(c.color).frame(height: 36)
                                .overlay(Circle().strokeBorder(Brand.text, lineWidth: color == c ? 3 : 0))
                                .onTapGesture { Haptics.selection(); color = c }
                                .accessibilityLabel(c.rawValue)
                                .accessibilityAddTraits(color == c ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 14) {
                        ForEach(Glyph.kids, id: \.self) { g in
                            Image(systemName: g).font(.title3).frame(width: 40, height: 40)
                                .foregroundStyle(glyph == g ? .white : Brand.text2)
                                .background(glyph == g ? color.color : Color.clear, in: Circle())
                                .onTapGesture { Haptics.selection(); glyph = g }
                                .accessibilityLabel(g)
                                .accessibilityAddTraits(glyph == g ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(kid == nil ? "New child" : "Edit child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let kid, !loaded else { return }
        loaded = true
        name = kid.name; color = kid.color; glyph = kid.symbol
        if kid.weeklyAllowance > 0 {
            allowanceText = kid.weeklyAllowance == kid.weeklyAllowance.rounded() ?
                String(Int(kid.weeklyAllowance)) : String(kid.weeklyAllowance)
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let allowance = max(0, Double(allowanceText.replacingOccurrences(of: ",", with: ".")) ?? 0)
        if let kid {
            kid.name = trimmed; kid.color = color; kid.symbol = glyph; kid.weeklyAllowance = allowance
        } else {
            let new = Kid(name: trimmed, color: color, symbol: glyph,
                          weeklyAllowance: allowance, sortIndex: nextIndex)
            if allowance > 0 { new.lastAllowancePaid = .now }
            context.insert(new)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
